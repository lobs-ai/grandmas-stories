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

    func testInitialWasInterruptedFalse() {
        XCTAssertFalse(recorder.wasInterrupted)
    }

    func testCurrentAveragePowerWhenNotRecording() {
        let power = recorder.currentAveragePower()
        XCTAssertLessThanOrEqual(power, 0)
    }

    func testIsSilentWhenNotRecording() {
        // No recorder active → default power -160 → silence
        XCTAssertTrue(recorder.isSilent())
    }

    func testAvailableDiskSpaceBytes() {
        let space = AudioRecorder.availableDiskSpaceBytes()
        XCTAssertNotNil(space)
        if let space = space {
            XCTAssertGreaterThan(space, 0)
        }
    }

    func testDiskSpaceCheckDoesNotCrash() {
        // On a dev machine with space, isDiskSpaceLow() should return false
        let isLow = AudioRecorder.isDiskSpaceLow()
        XCTAssertFalse(isLow, "Dev machine should not be critically low on disk space")
    }
}
