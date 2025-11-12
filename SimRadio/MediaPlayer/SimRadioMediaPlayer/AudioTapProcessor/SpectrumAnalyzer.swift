//
//  SpectrumAnalyzer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 21.05.2025.
//

import Accelerate
import AVFoundation
import Foundation

protocol SpectrumAnalyzerDelegate: AnyObject {
    func spectrumAnalyzer(_ analyzer: SpectrumAnalyzer, didUpdateSpectrum spectrum: [[Float]])
}

final class SpectrumAnalyzer {
    let frequencyBands: Int
    let mono: Bool
    let startFrequency: Float
    let spectrumScale: Float
    let endFrequency: Float
    let spectrumSmooth: Float
    let fftSize: Int
    var sampleRate: Double
    weak var delegate: SpectrumAnalyzerDelegate?
    private lazy var fftSetup = vDSP_create_fftsetup(
        vDSP_Length(Int(round(log2(Double(fftSize))))), FFTRadix(kFFTRadix2)
    )

    // Pre-allocated buffers
    private var aWeights: [Float]
    private var processingSamples: [Float]
    private var hannWindow: [Float]
    private var realPart: [Float]
    private var imagPart: [Float]
    private var amplitudes: [Float]
    private var weightedAmplitudes: [Float]
    private var spectrum: [Float]
    private var spectrumBuffer: [[Float]]
    private var bands: [Band]
    private var bandIndices: [(startIndex: Int, endIndex: Int)]

    init(
        fftSize: Int,
        sampleRate: Double = 48000.0,
        mono: Bool = true,
        frequencyBands: Int = 5,
        spectrumScale: Float = 6.0,
        startFrequency: Float = 100,
        endFrequency: Float = 10000,
        spectrumSmooth: Float = 0.5
    ) {
        precondition(fftSize > 0 && (fftSize & (fftSize - 1)) == 0, "fftSize must be a power of 2")

        self.sampleRate = sampleRate
        self.mono = mono
        self.frequencyBands = frequencyBands
        self.spectrumScale = spectrumScale
        self.startFrequency = startFrequency
        self.endFrequency = endFrequency
        self.spectrumSmooth = spectrumSmooth.clamped(to: 0.0 ... 1.0)

        self.fftSize = fftSize
        aWeights = Self.makeFrequencyWeights(fftSize: fftSize, sampleRate: sampleRate)
        processingSamples = .init(repeating: 0.0, count: fftSize)
        hannWindow = [Float](unsafeUninitializedCapacity: fftSize) { buffer, initializedCount in
            vDSP_hann_window(buffer.baseAddress!, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
            initializedCount = fftSize
        }
        realPart = .init(repeating: 0.0, count: fftSize / 2)
        imagPart = .init(repeating: 0.0, count: fftSize / 2)
        amplitudes = .init(repeating: 0.0, count: fftSize / 2)
        weightedAmplitudes = .init(repeating: 0.0, count: fftSize / 2)
        spectrum = .init(repeating: 0.0, count: frequencyBands)
        bands = Self.makeBands(
            frequencyBands: frequencyBands,
            startFrequency: startFrequency,
            endFrequency: endFrequency
        )

        bandIndices = Self.makeBandIndices(
            fftSize: fftSize,
            sampleRate: sampleRate,
            bands: bands
        )

        spectrumBuffer = .init(repeating: [Float](repeating: 0, count: bands.count), count: 2)
    }

    deinit {
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }

    func setSampleRate(_ sampleRate: Double) {
        guard sampleRate != self.sampleRate else { return }
        self.sampleRate = sampleRate
        aWeights = Self.makeFrequencyWeights(fftSize: fftSize, sampleRate: sampleRate)
        bandIndices = Self.makeBandIndices(
            fftSize: fftSize,
            sampleRate: sampleRate,
            bands: bands
        )
    }

    func analyse(bufferList: UnsafeMutablePointer<AudioBufferList>) {
        let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
        let channelCount = mono ? 1 : Int(ablPointer.count)

        if spectrumBuffer.count != channelCount {
            spectrumBuffer = .init(repeating: [Float](repeating: 0, count: bands.count), count: channelCount)
        }

        for i in 0 ..< channelCount {
            let buffer = ablPointer[i]
            guard let data = buffer.mData, buffer.mNumberChannels == 1 else { continue }
            let channelBuf = processingSamples.withUnsafeMutableBufferPointer { $0 }
            let frameCount = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
            guard frameCount > fftSize else { continue }
            memcpy(channelBuf.baseAddress, data, fftSize * MemoryLayout<Float>.size)
            let channel = channelBuf.baseAddress!

            // Compute FFT and store results in amplitudes
            fftChannel(channel, output: &amplitudes)

            // Compute weighted amplitudes using vDSP_vmul
            vDSP_vmul(
                amplitudes, 1,
                aWeights, 1,
                &weightedAmplitudes, 1,
                vDSP_Length(fftSize / 2)
            )

            // Compute max amplitude for each frequency band
            for (j, indices) in bandIndices.enumerated() {
                findMaxAmplitude(
                    for: indices,
                    in: weightedAmplitudes,
                    output: &spectrum[j]
                )
            }

            // Scale spectrum amplitudes by spectrumScale
            vDSP_vsmul(
                spectrum, 1,
                [spectrumScale], &spectrum, 1,
                vDSP_Length(frequencyBands)
            )

            let spectrum = highlightWaveform(spectrum: spectrum)

            // Apply smoothing to spectrum buffer
            let zipped = zip(spectrumBuffer[i], spectrum)
            spectrumBuffer[i] = zipped.map { $0.0 * spectrumSmooth + $0.1 * (1 - spectrumSmooth) }
        }
        delegate?.spectrumAnalyzer(self, didUpdateSpectrum: spectrumBuffer)
    }
}

private extension SpectrumAnalyzer {
    struct Band {
        let lowerFrequency: Float
        let upperFrequency: Float
    }

    func fftChannel(_ channel: UnsafeMutablePointer<Float>, output amplitudes: inout [Float]) {
        vDSP_vmul(channel, 1, hannWindow, 1, channel, 1, vDSP_Length(fftSize))

        // Pack real numbers into complex numbers (fftInOut)
        // required by FFT, which serves as both input and output
        let realptr = realPart.withUnsafeMutableBufferPointer { $0 }
        let imagptr = imagPart.withUnsafeMutableBufferPointer { $0 }
        var fftInOut = DSPSplitComplex(realp: realptr.baseAddress!, imagp: imagptr.baseAddress!)

        let typeConvertedTransferBuffer = channel.withMemoryRebound(to: DSPComplex.self, capacity: fftSize) { $0 }
        vDSP_ctoz(typeConvertedTransferBuffer, 2, &fftInOut, 1, vDSP_Length(fftSize / 2))

        // Perform FFT
        vDSP_fft_zrip(fftSetup!, &fftInOut, 1, vDSP_Length(round(log2(Double(fftSize)))), FFTDirection(FFT_FORWARD))

        // Adjust FFT results and calculate amplitudes
        fftInOut.imagp[0] = 0
        let fftNormFactor = Float(1.0 / Float(fftSize))
        vDSP_vsmul(fftInOut.realp, 1, [fftNormFactor], fftInOut.realp, 1, vDSP_Length(fftSize / 2))
        vDSP_vsmul(fftInOut.imagp, 1, [fftNormFactor], fftInOut.imagp, 1, vDSP_Length(fftSize / 2))
        vDSP_zvabs(&fftInOut, 1, &amplitudes, 1, vDSP_Length(fftSize / 2))
        amplitudes[0] /= 2 // DC component amplitude needs to be divided by 2
    }

    func findMaxAmplitude(
        for indices: (startIndex: Int, endIndex: Int),
        in amplitudes: [Float],
        output maxAmplitude: inout Float
    ) {
        // Find maximum amplitude in the specified frequency band
        amplitudes.withUnsafeBufferPointer { buffer in
            vDSP_maxv(
                buffer.baseAddress! + indices.startIndex,
                1,
                &maxAmplitude,
                vDSP_Length(indices.endIndex - indices.startIndex + 1)
            )
        }
    }

    func highlightWaveform(spectrum: [Float]) -> [Float] {
        // Define weights array, the middle 5 represents the weight of the current element
        // Can be modified freely, but the count must be odd
        let weights: [Float] = [2, 3, 5, 3, 2]
        let totalWeights = Float(weights.reduce(0, +))
        let startIndex = weights.count / 2
        // The first few elements don't participate in calculation
        var averagedSpectrum = Array(spectrum[0 ..< startIndex])
        for i in startIndex ..< spectrum.count - startIndex {
            // zip function: zip([a,b,c], [x,y,z]) -> [(a,x), (b,y), (c,z)]
            let zipped = zip(Array(spectrum[i - startIndex ... i + startIndex]), weights)
            let averaged = zipped.map { $0.0 * $0.1 }.reduce(0, +) / totalWeights
            averagedSpectrum.append(averaged)
        }
        // The last few elements don't participate in calculation
        averagedSpectrum.append(contentsOf: Array(spectrum.suffix(startIndex)))
        return averagedSpectrum
    }

    static func makeFrequencyWeights(fftSize: Int, sampleRate: Double) -> [Float] {
        guard fftSize > 0 else { return [] }
        let deltaF = Float(sampleRate) / Float(fftSize)
        let bins = fftSize / 2

        var f = (0 ..< bins).map { Float($0) * deltaF }
        f = f.map { $0 * $0 }

        let c1 = powf(12194.217, 2.0)
        let c2 = powf(20.598997, 2.0)
        let c3 = powf(107.65265, 2.0)
        let c4 = powf(737.86223, 2.0)

        let num = f.map { c1 * $0 * $0 }
        let den = f.map { ($0 + c2) * sqrtf(max(0, ($0 + c3) * ($0 + c4))) * ($0 + c1) }

        let weights = num.enumerated().map { index, element -> Float in
            guard den[index] != 0 else { return 0.0 }
            return 1.2589 * element / den[index]
        }
        return weights
    }

    static func makeBandIndices(
        fftSize: Int,
        sampleRate: Double,
        bands: [Band]
    ) -> [(startIndex: Int, endIndex: Int)] {
        // Precompute band indices based on current sample rate
        let bandWidth = Float(sampleRate) / Float(fftSize)
        return bands.map {
            let startIndex = Int(round($0.lowerFrequency / bandWidth))
            let endIndex = min(Int(round($0.upperFrequency / bandWidth)), fftSize / 2 - 1)
            return (startIndex, endIndex)
        }
    }

    static func makeBands(
        frequencyBands: Int,
        startFrequency: Float,
        endFrequency: Float
    ) -> [Band] {
        var bands: [Band] = []
        // Determine the growth factor based on start/end frequencies and number of bands: 2^n
        let n = log2(endFrequency / startFrequency) / Float(frequencyBands)
        var nextBand: (lowerFrequency: Float, upperFrequency: Float) = (startFrequency, 0)
        for i in 1 ... frequencyBands {
            // The upper frequency of a band is 2^n times the lower frequency
            let highFrequency = nextBand.lowerFrequency * powf(2, n)
            nextBand.upperFrequency = i == frequencyBands ? endFrequency : highFrequency
            bands.append(
                Band(lowerFrequency: nextBand.lowerFrequency, upperFrequency: nextBand.upperFrequency)
            )
            nextBand.lowerFrequency = highFrequency
        }
        return bands
    }
}
