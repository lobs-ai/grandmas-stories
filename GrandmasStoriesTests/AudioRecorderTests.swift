import XCTest
@testable import GrandmasStories

final class AudioRecorderTests: XCTestCase {

    var recorder: AudioRecorder!

    override func setUp() {
        super.setUp()
        recorder = AudioRecorder()
    }

    override func tearDown() {
        recorder = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(recorder.isRecording)
        XCTAssertFalse(recorder.isPlaying)
        XCTAssertNil(recorder.recordingURL)
        XCTAssertFalse(recorder.silenceDetected)
    }

    func testCurrentAveragePowerWhenNotRecording() {
        // Should return very low value when no recorder active
        let power = recorder.currentAveragePower()
        XCTAssertLessThanOrEqual(power, 0)
    }

    func testIsSilentWhenNotRecording() {
        // No recorder active → default power -160 → silence
        XCTAssertTrue(recorder.isSilent())
    }
}
