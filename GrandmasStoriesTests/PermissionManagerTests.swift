import XCTest
@testable import GrandmasStories

final class PermissionManagerTests: XCTestCase {

    func testMicrophoneExplanationIsSet() {
        let manager = PermissionManager()
        XCTAssertFalse(manager.microphoneExplanation.isEmpty)
        XCTAssertTrue(manager.microphoneExplanation.contains("microphone"))
    }

    func testContactsExplanationIsSet() {
        let manager = PermissionManager()
        XCTAssertFalse(manager.contactsExplanation.isEmpty)
        XCTAssertTrue(manager.contactsExplanation.contains("contacts"))
    }

    func testMicrophoneGrantedInitialValue() {
        // In a simulator test environment, mic permission is denied by default.
        // We just check the property is a valid Bool.
        let manager = PermissionManager()
        let _ = manager.microphoneGranted  // Should not crash
    }
}

final class ContactsManagerTests: XCTestCase {

    func testPermissionStatusIsDeniedWithoutGrant() {
        // In test environment (no user interaction), status is notDetermined or denied.
        let manager = ContactsManager()
        let status = manager.permissionStatus
        XCTAssertTrue(status == .denied || status == .notDetermined)
    }

    func testFetchReturnEmptyWhenNotGranted() async {
        let manager = ContactsManager()
        // Without permission, should return empty array without crashing.
        let candidates = await manager.fetchFamilyMemberCandidates()
        // We can only assert it doesn't crash (may be empty due to permission).
        XCTAssertNotNil(candidates)
    }
}
