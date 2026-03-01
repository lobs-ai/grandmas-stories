import XCTest
@testable import GrandmasStories

final class FamilySharingSetupTests: XCTestCase {

    // MARK: - FamilyMember

    func testFamilyMemberInit_defaults() {
        let member = FamilyMember(name: "Grandma Rose")
        XCTAssertFalse(member.id.uuidString.isEmpty)
        XCTAssertEqual(member.name, "Grandma Rose")
        XCTAssertNil(member.phoneNumber)
        XCTAssertNil(member.contactIdentifier)
    }

    func testFamilyMemberInit_withPhone() {
        let member = FamilyMember(name: "Uncle Bob", phoneNumber: "555-1234")
        XCTAssertEqual(member.phoneNumber, "555-1234")
    }

    func testFamilyMember_isIdentifiable() {
        let m1 = FamilyMember(name: "Alice")
        let m2 = FamilyMember(name: "Alice")
        XCTAssertNotEqual(m1.id, m2.id) // distinct UUIDs
    }

    func testFamilyMember_codable() throws {
        let member = FamilyMember(name: "Test", phoneNumber: "123", contactIdentifier: "abc")
        let data = try JSONEncoder().encode(member)
        let decoded = try JSONDecoder().decode(FamilyMember.self, from: data)
        XCTAssertEqual(decoded.id, member.id)
        XCTAssertEqual(decoded.name, member.name)
        XCTAssertEqual(decoded.phoneNumber, member.phoneNumber)
        XCTAssertEqual(decoded.contactIdentifier, member.contactIdentifier)
    }

    // MARK: - SharingMethod

    func testSharingMethod_allCases() {
        XCTAssertEqual(SharingMethod.allCases.count, 2)
        XCTAssertTrue(SharingMethod.allCases.contains(.iMessage))
        XCTAssertTrue(SharingMethod.allCases.contains(.whatsApp))
    }

    func testSharingMethod_rawValues() {
        XCTAssertEqual(SharingMethod.iMessage.rawValue, "iMessage")
        XCTAssertEqual(SharingMethod.whatsApp.rawValue, "whatsApp")
    }

    func testSharingMethod_codable() throws {
        let data = try JSONEncoder().encode(SharingMethod.whatsApp)
        let decoded = try JSONDecoder().decode(SharingMethod.self, from: data)
        XCTAssertEqual(decoded, .whatsApp)
    }

    // MARK: - AppSettings with family members

    func testAppSettings_defaultHasNoMembers() {
        let settings = AppSettings()
        XCTAssertTrue(settings.familyMembers.isEmpty)
        XCTAssertEqual(settings.sharingMethod, .iMessage)
        XCTAssertFalse(settings.hasCompletedSetup)
    }

    func testAppSettings_saveAndLoadFamilyMembers() {
        let defaults = UserDefaults(suiteName: "test_family_\(UUID().uuidString)")!
        let storage = StorageManager(userDefaults: defaults)

        var settings = storage.loadSettings()
        settings.familyMembers = [
            FamilyMember(name: "Mom", phoneNumber: "555-0001"),
            FamilyMember(name: "Dad", phoneNumber: "555-0002")
        ]
        settings.sharingMethod = .whatsApp
        settings.hasCompletedSetup = true
        storage.saveSettings(settings)

        let loaded = storage.loadSettings()
        XCTAssertEqual(loaded.familyMembers.count, 2)
        XCTAssertEqual(loaded.familyMembers[0].name, "Mom")
        XCTAssertEqual(loaded.familyMembers[1].name, "Dad")
        XCTAssertEqual(loaded.sharingMethod, .whatsApp)
        XCTAssertTrue(loaded.hasCompletedSetup)
    }

    func testAppSettings_removeFamilyMember() {
        let defaults = UserDefaults(suiteName: "test_remove_\(UUID().uuidString)")!
        let storage = StorageManager(userDefaults: defaults)

        let alice = FamilyMember(name: "Alice", phoneNumber: "111")
        let bob = FamilyMember(name: "Bob", phoneNumber: "222")

        var settings = AppSettings()
        settings.familyMembers = [alice, bob]
        storage.saveSettings(settings)

        var loaded = storage.loadSettings()
        loaded.familyMembers.removeAll { $0.id == alice.id }
        storage.saveSettings(loaded)

        let final = storage.loadSettings()
        XCTAssertEqual(final.familyMembers.count, 1)
        XCTAssertEqual(final.familyMembers[0].name, "Bob")
    }
}
