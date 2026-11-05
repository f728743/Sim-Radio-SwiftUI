import Foundation
@testable import Services
import XCTest

private class DownloadURLProtocol: URLProtocol {
    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        if request.url?.host == "failure.test" {
            client?.urlProtocol(self, didFailWithError: URLError(.timedOut))
        }
    }

    override func stopLoading() {}
}

@MainActor
final class DownloadQueueTests: XCTestCase {
    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DownloadURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    func testTransportFailureFinishesEventStream() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let download = try FileDownload(
            url: XCTUnwrap(URL(string: "https://failure.test/audio.m4a")),
            destinationDirectory: .temporaryDirectory,
            urlSession: session
        )
        let finished = expectation(description: "Failure closes the stream")
        let task = Task {
            var failures = 0
            for await event in download.events {
                if case .failed = event {
                    failures += 1
                }
            }
            XCTAssertEqual(failures, 1)
            finished.fulfill()
        }
        defer { task.cancel() }
        download.start()
        let result = await XCTWaiter.fulfillment(of: [finished], timeout: 3)
        XCTAssertEqual(result, .completed)
    }

    func testFailureReleasesSlotForNextRequest() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let queue = DownloadQueue(
            destinationDirectory: .temporaryDirectory,
            maxConcurrentDownloads: 1,
            session: session
        )
        let requests = try (1 ... 2).map {
            try DownloadQueue.DownloadRequest(
                sourceURL: XCTUnwrap(URL(string: "https://failure.test/\($0).m4a")),
                destinationDirectoryPath: "download-tests"
            )
        }
        let finished = expectation(description: "Both requests fail instead of blocking the queue")
        finished.expectedFulfillmentCount = 2
        let events = await queue.events
        let task = Task {
            for await event in events {
                if case .failed = event.state {
                    finished.fulfill()
                }
            }
        }
        defer { task.cancel() }
        for request in requests {
            await queue.append(request)
        }
        let result = await XCTWaiter.fulfillment(of: [finished], timeout: 3)
        XCTAssertEqual(result, .completed)
    }

    func testCancelAllCancelsQueuedRequestsWithoutStartingThem() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let queue = DownloadQueue(
            destinationDirectory: .temporaryDirectory,
            maxConcurrentDownloads: 1,
            session: session
        )
        let requests = try (1 ... 3).map {
            try DownloadQueue.DownloadRequest(
                sourceURL: XCTUnwrap(URL(string: "https://holding.test/\($0).m4a")),
                destinationDirectoryPath: "download-tests"
            )
        }
        let finished = expectation(description: "All requests canceled")
        let events = await queue.events
        let task = Task {
            var canceled: Set<DownloadQueue.DownloadRequest> = []
            for await event in events {
                if case .progress = event.state {
                    XCTAssertEqual(event.downloadRequest, requests[0])
                }
                if case .canceled = event.state {
                    canceled.insert(event.downloadRequest)
                    if canceled.count == requests.count {
                        finished.fulfill()
                        return
                    }
                }
            }
        }
        defer { task.cancel() }
        for request in requests {
            await queue.append(request)
        }
        await queue.cancelAllDownloads()
        let result = await XCTWaiter.fulfillment(of: [finished], timeout: 3)
        XCTAssertEqual(result, .completed)
    }
}
