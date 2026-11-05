@testable import Player
import XCTest

final class NonRepeatingRandomizerTests: XCTestCase {
    func testSingleTrackRemainsPlayable() throws {
        var randomizer = try XCTUnwrap(NonRepeatingRandomizer(elements: [42], avoidRepeatsRatio: 0.5))
        var generator = SystemRandomNumberGenerator()
        for _ in 0 ..< 20 {
            XCTAssertEqual(randomizer.next(generator: &generator), 42)
        }
    }

    func testFullAvoidanceRatioDoesNotExhaustPool() throws {
        var randomizer = try XCTUnwrap(NonRepeatingRandomizer(elements: [1, 2], avoidRepeatsRatio: 1))
        var generator = SystemRandomNumberGenerator()
        var previous = randomizer.next(generator: &generator)
        for _ in 0 ..< 20 {
            let next = randomizer.next(generator: &generator)
            XCTAssertNotEqual(previous, next)
            previous = next
        }
    }
}
