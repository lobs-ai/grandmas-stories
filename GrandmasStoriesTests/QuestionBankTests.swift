import XCTest
@testable import GrandmasStories

final class QuestionBankTests: XCTestCase {

    // MARK: - QuestionBank structure

    func testExactly12Categories() {
        XCTAssertEqual(QuestionBank.categories.count, 12)
    }

    func testAllCategoriesHaveAtLeast8Questions() {
        for category in QuestionBank.categories {
            XCTAssertGreaterThanOrEqual(
                category.questions.count, 8,
                "Category '\(category.name)' has fewer than 8 questions"
            )
        }
    }

    func testAllCategoriesHaveUniqueIds() {
        let ids = QuestionBank.categories.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Duplicate category IDs found")
    }

    func testAllCategoriesHaveNonEmptyIcon() {
        for category in QuestionBank.categories {
            XCTAssertFalse(category.icon.isEmpty, "Category '\(category.name)' has empty icon")
        }
    }

    func testAllCategoriesHaveNonEmptyName() {
        for category in QuestionBank.categories {
            XCTAssertFalse(category.name.isEmpty, "Category has empty name")
        }
    }

    func testAllQuestionsNonEmpty() {
        for category in QuestionBank.categories {
            for (i, question) in category.questions.enumerated() {
                XCTAssertFalse(question.isEmpty, "Category '\(category.name)' question \(i) is empty")
            }
        }
    }

    func testExpectedCategoryIdsPresent() {
        let ids = Set(QuestionBank.categories.map { $0.id })
        let expected = ["childhood", "children", "spouse", "parents", "favorites",
                        "holidays", "lessons", "school", "friends", "places", "food", "funny"]
        for id in expected {
            XCTAssertTrue(ids.contains(id), "Missing expected category id: \(id)")
        }
    }

    // MARK: - UsedQuestion tracking via StorageManager

    func testMarkQuestionUsed() {
        let defaults = UserDefaults(suiteName: "test-qb-\(UUID().uuidString)")!
        let storage = StorageManager(userDefaults: defaults)

        storage.markQuestionUsed(categoryId: "childhood", questionIndex: 0)
        storage.markQuestionUsed(categoryId: "childhood", questionIndex: 2)

        let used = storage.loadUsedQuestions()
        XCTAssertEqual(used.count, 2)
        XCTAssertTrue(used.contains { $0.categoryId == "childhood" && $0.questionIndex == 0 })
        XCTAssertTrue(used.contains { $0.categoryId == "childhood" && $0.questionIndex == 2 })
    }

    func testUnusedQuestionsFilteredCorrectly() {
        let defaults = UserDefaults(suiteName: "test-qb2-\(UUID().uuidString)")!
        let storage = StorageManager(userDefaults: defaults)

        let category = QuestionBank.categories.first { $0.id == "childhood" }!
        let totalCount = category.questions.count

        // Mark first 3 used
        for i in 0..<3 {
            storage.markQuestionUsed(categoryId: category.id, questionIndex: i)
        }

        let usedIndices = Set(storage.loadUsedQuestions()
            .filter { $0.categoryId == category.id }
            .map { $0.questionIndex })
        let unusedCount = category.questions.indices.filter { !usedIndices.contains($0) }.count

        XCTAssertEqual(unusedCount, totalCount - 3)
    }

    func testResetCategoryRemovesUsedQuestions() {
        let defaults = UserDefaults(suiteName: "test-qb3-\(UUID().uuidString)")!
        let storage = StorageManager(userDefaults: defaults)

        storage.markQuestionUsed(categoryId: "childhood", questionIndex: 0)
        storage.markQuestionUsed(categoryId: "funny", questionIndex: 1)

        // Reset childhood only
        var all = storage.loadUsedQuestions()
        all.removeAll { $0.categoryId == "childhood" }
        storage.saveUsedQuestions(all)

        let remaining = storage.loadUsedQuestions()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].categoryId, "funny")
    }
}
