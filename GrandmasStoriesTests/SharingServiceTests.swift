import XCTest
@testable import GrandmasStories

@MainActor
final class SharingServiceTests: XCTestCase {

    var service: SharingService!

    override func setUp() {
        super.setUp()
        service = SharingService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(service.showShareSheet)
        XCTAssertFalse(service.showMessageComposer)
        XCTAssertFalse(service.showAlert)
        XCTAssertEqual(service.alertTitle, "")
        XCTAssertEqual(service.alertMessage, "")
        XCTAssertTrue(service.shareItems.isEmpty)
        XCTAssertTrue(service.messageRecipients.isEmpty)
        XCTAssertNil(service.messageAttachmentURL)
    }

    func testShareViaIMessage_noRecipients_showsAlert() {
        let recording = Recording(title: "Test Story", fileName: "test.m4a")
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        service.shareRecording(recording, via: .iMessage, to: [], audioURL: audioURL)
        XCTAssertTrue(service.showAlert)
        XCTAssertFalse(service.showMessageComposer)
        XCTAssertEqual(service.alertTitle, "No Recipients")
    }

    func testShareViaIMessage_membersWithoutPhones_showsAlert() {
        let member = FamilyMember(name: "Alice", phoneNumber: nil)
        let recording = Recording(title: "Story", fileName: "story.m4a")
        let audioURL = URL(fileURLWithPath: "/tmp/story.m4a")
        service.shareRecording(recording, via: .iMessage, to: [member], audioURL: audioURL)
        XCTAssertTrue(service.showAlert)
        XCTAssertEqual(service.alertTitle, "No Recipients")
    }

    func testShareMessageContainsAppName() {
        XCTAssertTrue(SharingService.shareMessage.contains(SharingService.appName))
        XCTAssertTrue(SharingService.shareMessage.contains("🎙️"))
    }

    func testDidCompleteSharing_callsOnComplete() {
        var callbackCalled = false
        let recording = Recording(title: "Story", fileName: "story.m4a")
        let audioURL = URL(fileURLWithPath: "/tmp/story.m4a")
        service.shareRecording(recording, via: .whatsApp, to: [], audioURL: audioURL) {
            callbackCalled = true
        }
        service.didCompleteSharing()
        XCTAssertTrue(callbackCalled)
    }

    func testShareViaWhatsApp_alwaysShowsShareSheet() {
        let recording = Recording(title: "Story", fileName: "story.m4a")
        let audioURL = URL(fileURLWithPath: "/tmp/story.m4a")
        service.shareRecording(recording, via: .whatsApp, to: [], audioURL: audioURL)
        XCTAssertTrue(service.showShareSheet)
        XCTAssertFalse(service.shareItems.isEmpty)
    }
}
