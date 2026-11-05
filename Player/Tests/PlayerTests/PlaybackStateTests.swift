import MediaLibrary
@testable import Player
import XCTest

@MainActor
private final class RealPlayerSpy: RealRadioMediaPlayer {
    var starts = 0
    var stops = 0
    func playStation(withID _: RealStation.ID) {
        starts += 1
    }

    func stop() {
        stops += 1
    }
}

@MainActor
final class PlaybackStateTests: XCTestCase {
    func testLoadingCanBeCanceledAndLateEventsAreIgnored() {
        let player = MediaPlayer()
        let transport = RealPlayerSpy()
        player.realPlayer = transport
        let station = RealStation.ID(stationUUID: "station-a")
        let media = MediaID.realRadio(station)
        player.play(media, of: [media])
        XCTAssertEqual(player.state, .loading(media: media, mode: nil))
        player.togglePlayPause()
        XCTAssertEqual(transport.stops, 1)
        player.realRadioMediaPlayer(transport, stationID: station, didChangeStatus: .playing)
        XCTAssertEqual(player.state, .paused(media: media, mode: nil))
    }

    func testFailureStopsTransportAndAllowsRetry() {
        let player = MediaPlayer()
        let transport = RealPlayerSpy()
        player.realPlayer = transport
        let station = RealStation.ID(stationUUID: "station-a")
        let media = MediaID.realRadio(station)
        player.play(media, of: [media])
        player.realRadioMediaPlayer(transport, stationID: station, didChangeStatus: .failed("Offline"))
        XCTAssertEqual(player.state, .failed(media: media, mode: nil, message: "Offline"))
        XCTAssertEqual(transport.stops, 1)
        player.togglePlayPause()
        XCTAssertEqual(transport.starts, 2)
        XCTAssertEqual(player.state, .loading(media: media, mode: nil))
        player.realRadioMediaPlayer(transport, stationID: station, didChangeStatus: .playing)
        XCTAssertEqual(player.state, .playing(media: media, mode: nil))
        player.togglePlayPause()
    }

    func testPreviousStationCannotChangeCurrentState() {
        let player = MediaPlayer()
        let transport = RealPlayerSpy()
        player.realPlayer = transport
        let first = RealStation.ID(stationUUID: "station-a")
        let second = RealStation.ID(stationUUID: "station-b")
        let items: [MediaID] = [.realRadio(first), .realRadio(second)]
        player.play(items[0], of: items)
        player.forward()
        player.realRadioMediaPlayer(transport, stationID: first, didChangeStatus: .failed("Old failure"))
        XCTAssertEqual(player.state, .loading(media: items[1], mode: nil))
        player.togglePlayPause()
    }
}
