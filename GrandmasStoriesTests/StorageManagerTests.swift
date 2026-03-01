import XCTest
@testable import GrandmasStories

final class StorageManagerTests: XCTestCase {

    var storage: StorageManager!
    var defaults: UserDefaults!
    var tempDir: URL!

    override func setUpWithError() throws {
        defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        // Use a temp directory to avoid touching real Documents
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        storage = StorageManager(userDefaults: defaults, fileManager: .default)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        defaults.removePersistentDomain(forName: defaults.volatileDomainNames.first ?? "")
    }

    // MARK: - AppSettings

    func testDefaultSettings() {
        let settings = storage.loadSettings()
        XCTAssertFalse(settings.hasCompletedSetup)
        XCTAssertTrue(settings.familyMembers.isEmpty)
        XCTAssertEqual(settings.sharingMethod, .iMessage)
        XCTAssertFalse(settings.iCloudBackupEnabled)
    }

    func testSaveAndLoadSettings() {
        var settings = AppSettings()
        settings.hasCompletedSetup = true
        settings.sharingMethod = .whatsApp
        settings.iCloudBackupEnabled = true
        let member = FamilyMember(name: "Mom", phoneNumber: "555-1234")
        settings.familyMembers = [member]

        storage.saveSettings(settings)
        let loaded = storage.loadSettings()

        XCTAssertTrue(loaded.hasCompletedSetup)
        XCTAssertEqual(loaded.sharingMethod, .whatsApp)
        XCTAssertTrue(loaded.iCloudBackupEnabled)
        XCTAssertEqual(loaded.familyMembers.count, 1)
        XCTAssertEqual(loaded.familyMembers[0].name, "Mom")
        XCTAssertEqual(loaded.familyMembers[0].phoneNumber, "555-1234")
    }

    // MARK: - UsedQuestions

    func testDefaultUsedQuestions() {
        let questions = storage.loadUsedQuestions()
        XCTAssertTrue(questions.isEmpty)
    }

    func testSaveAndLoadUsedQuestions() {
        let q1 = UsedQuestion(categoryId: "childhood", questionIndex: 0)
        let q2 = UsedQuestion(categoryId: "work", questionIndex: 3)
        storage.saveUsedQuestions([q1, q2])

        let loaded = storage.loadUsedQuestions()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].categoryId, "childhood")
        XCTAssertEqual(loaded[1].questionIndex, 3)
    }

    func testMarkQuestionUsed() {
        storage.markQuestionUsed(categoryId: "family", questionIndex: 2)
        storage.markQuestionUsed(categoryId: "family", questionIndex: 5)

        let loaded = storage.loadUsedQuestions()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].categoryId, "family")
        XCTAssertEqual(loaded[0].questionIndex, 2)
        XCTAssertEqual(loaded[1].questionIndex, 5)
    }

    // MARK: - Audio Files

    func testSaveAndDeleteAudioFile() throws {
        let data = Data("fake audio".utf8)
        let fileName = "test-\(UUID().uuidString).m4a"
        let url = try storage.saveAudioFile(data: data, fileName: fileName)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        try storage.deleteAudioFile(fileName: fileName)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testListRecordingFileNames() throws {
        let fileName1 = "rec-\(UUID().uuidString).m4a"
        let fileName2 = "rec-\(UUID().uuidString).m4a"
        try storage.saveAudioFile(data: Data("a".utf8), fileName: fileName1)
        try storage.saveAudioFile(data: Data("b".utf8), fileName: fileName2)

        let files = try storage.listRecordingFileNames()
        XCTAssertTrue(files.contains(fileName1))
        XCTAssertTrue(files.contains(fileName2))

        // Cleanup
        try storage.deleteAudioFile(fileName: fileName1)
        try storage.deleteAudioFile(fileName: fileName2)
    }

    func testFileSizeAfterSave() throws {
        let content = Data("hello world".utf8)
        let fileName = "size-\(UUID().uuidString).m4a"
        try storage.saveAudioFile(data: content, fileName: fileName)

        let size = storage.fileSize(fileName: fileName)
        XCTAssertEqual(size, Int64(content.count))

        try storage.deleteAudioFile(fileName: fileName)
    }

    func testDeleteNonExistentFileDoesNotThrow() {
        XCTAssertNoThrow(try storage.deleteAudioFile(fileName: "nonexistent.m4a"))
    }
}

// MARK: - ModelTests

final class ModelTests: XCTestCase {

    func testRecordingDefaults() {
        let r = Recording(title: "Story 1", fileName: "story1.m4a")
        XCTAssertNotNil(r.id)
        XCTAssertNil(r.categoryId)
        XCTAssertNil(r.questionText)
        XCTAssertEqual(r.duration, 0)
        XCTAssertEqual(r.fileSize, 0)
    }

    func testCategoryInit() {
        let cat = Category(id: "childhood", name: "Childhood", icon: "house.fill", questions: ["Q1", "Q2"])
        XCTAssertEqual(cat.questions.count, 2)
        XCTAssertEqual(cat.icon, "house.fill")
    }

    func testFamilyMemberOptionals() {
        let member = FamilyMember(name: "Dad")
        XCTAssertNil(member.phoneNumber)
        XCTAssertNil(member.contactIdentifier)
    }

    func testSharingMethodCases() {
        XCTAssertEqual(SharingMethod.allCases.count, 2)
        XCTAssertEqual(SharingMethod.iMessage.rawValue, "iMessage")
        XCTAssertEqual(SharingMethod.whatsApp.rawValue, "whatsApp")
    }

    func testAppSettingsCodable() throws {
        var settings = AppSettings(sharingMethod: .whatsApp, hasCompletedSetup: true, iCloudBackupEnabled: true)
        settings.familyMembers = [FamilyMember(name: "Grandma")]
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        XCTAssertEqual(decoded.sharingMethod, .whatsApp)
        XCTAssertTrue(decoded.hasCompletedSetup)
        XCTAssertEqual(decoded.familyMembers[0].name, "Grandma")
    }

    func testUsedQuestionCodable() throws {
        let q = UsedQuestion(categoryId: "travel", questionIndex: 7)
        let data = try JSONEncoder().encode(q)
        let decoded = try JSONDecoder().decode(UsedQuestion.self, from: data)
        XCTAssertEqual(decoded.categoryId, "travel")
        XCTAssertEqual(decoded.questionIndex, 7)
    }
}
