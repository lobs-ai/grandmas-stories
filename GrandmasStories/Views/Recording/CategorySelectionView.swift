import SwiftUI

struct CategorySelectionView: View {
    @StateObject private var storageManager = StorageManager()
    @State private var usedQuestions: [UsedQuestion] = []

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            if QuestionBank.categories.isEmpty {
                emptyCategoriesView
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(QuestionBank.categories) { category in
                        let unused = unusedCount(for: category)
                        NavigationLink(destination: QuestionView(category: category)) {
                            CategoryCard(category: category, unusedCount: unused)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(category.name), \(unused) questions remaining")
                        .accessibilityHint("Tap to see a question from this category")
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Choose a Category")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            usedQuestions = storageManager.loadUsedQuestions()
        }
    }

    private var emptyCategoriesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No categories available")
                .font(.title3.weight(.semibold))
            Text("Check back soon for story prompts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 80)
    }

    private func unusedCount(for category: QuestionCategory) -> Int {
        let usedIndices = usedQuestions
            .filter { $0.categoryId == category.id }
            .map { $0.questionIndex }
        return category.questions.indices.filter { !usedIndices.contains($0) }.count
    }
}

// MARK: - CategoryCard

struct CategoryCard: View {
    let category: QuestionCategory
    let unusedCount: Int

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 36))
                .foregroundStyle(AppColors.warmOrange)
                .accessibilityHidden(true)

            Text(category.name)
                .font(.footnote.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .lineLimit(3)

            Text(unusedCount > 0 ? "\(unusedCount) questions left" : "All done!")
                .font(.caption2)
                .foregroundStyle(unusedCount > 0 ? .secondary : AppColors.warmOrange)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.warmOrange.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView()
    }
}
