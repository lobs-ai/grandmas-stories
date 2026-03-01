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
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(QuestionBank.categories) { category in
                    let unused = unusedCount(for: category)
                    NavigationLink(destination: QuestionView(category: category)) {
                        CategoryCard(category: category, unusedCount: unused)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .navigationTitle("Choose a Category")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            usedQuestions = storageManager.loadUsedQuestions()
        }
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
                .foregroundStyle(.blue)

            Text(category.name)
                .font(.footnote.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .lineLimit(3)

            Text("\(unusedCount) questions left")
                .font(.caption2)
                .foregroundStyle(unusedCount > 0 ? .secondary : .orange)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.blue.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView()
    }
}
