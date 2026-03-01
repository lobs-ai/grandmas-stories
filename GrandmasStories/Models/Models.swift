import Foundation

// MARK: - Recording

struct Recording: Codable, Identifiable {
    let id: UUID
    var title: String
    var categoryId: String?
    var questionText: String?
    let fileName: String
    let createdAt: Date
    var duration: TimeInterval
    var fileSize: Int64

    init(
        id: UUID = UUID(),
        title: String,
        categoryId: String? = nil,
        questionText: String? = nil,
        fileName: String,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        fileSize: Int64 = 0
    ) {
        self.id = id
        self.title = title
        self.categoryId = categoryId
        self.questionText = questionText
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
        self.fileSize = fileSize
    }
}

// MARK: - Category

struct Category: Codable, Identifiable {
    let id: String
    var name: String
    var icon: String  // SF Symbol name
    var questions: [String]

    init(id: String, name: String, icon: String, questions: [String] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.questions = questions
    }
}

// MARK: - FamilyMember

struct FamilyMember: Codable, Identifiable {
    let id: UUID
    var name: String
    var phoneNumber: String?
    var contactIdentifier: String?

    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String? = nil,
        contactIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.contactIdentifier = contactIdentifier
    }
}

// MARK: - SharingMethod

enum SharingMethod: String, Codable, CaseIterable {
    case iMessage
    case whatsApp
}

// MARK: - AppSettings

struct AppSettings: Codable {
    var sharingMethod: SharingMethod
    var familyMembers: [FamilyMember]
    var hasCompletedSetup: Bool
    var iCloudBackupEnabled: Bool

    init(
        sharingMethod: SharingMethod = .iMessage,
        familyMembers: [FamilyMember] = [],
        hasCompletedSetup: Bool = false,
        iCloudBackupEnabled: Bool = false
    ) {
        self.sharingMethod = sharingMethod
        self.familyMembers = familyMembers
        self.hasCompletedSetup = hasCompletedSetup
        self.iCloudBackupEnabled = iCloudBackupEnabled
    }
}

// MARK: - UsedQuestion

struct UsedQuestion: Codable {
    let categoryId: String
    let questionIndex: Int
    let usedAt: Date

    init(categoryId: String, questionIndex: Int, usedAt: Date = Date()) {
        self.categoryId = categoryId
        self.questionIndex = questionIndex
        self.usedAt = usedAt
    }
}
