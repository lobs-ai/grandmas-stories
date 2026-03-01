import SwiftUI

struct QuestionView: View {
    let category: QuestionCategory

    @StateObject private var storageManager = StorageManager()
    @State private var usedQuestions: [UsedQuestion] = []
    @State private var currentQuestionIndex: Int? = nil

    // MARK: - Computed

    private var usedIndices: Set<Int> {
        Set(usedQuestions.filter { $0.categoryId == category.id }.map { $0.questionIndex })
    }

    private var availableIndices: [Int] {
        category.questions.indices.filter { !usedIndices.contains($0) }
    }

    private var currentQuestion: String? {
        guard let idx = currentQuestionIndex else { return nil }
        return category.questions[idx]
    }

    private var allUsed: Bool {
        availableIndices.isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if allUsed {
                allUsedView
            } else if let question = currentQuestion {
                questionContentView(question: question)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadState)
    }

    // MARK: - Subviews

    private func questionContentView(question: String) -> some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: category.icon)
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text(question)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 14) {
                NavigationLink(destination: RecordingView(question: question, categoryId: category.id)) {
                    Label("Start Recording", systemImage: "mic.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color.blue.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button(action: skipQuestion) {
                    Label("Skip Question", systemImage: "forward.fill")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var allUsedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎉")
                .font(.system(size: 64))

            Text("You've answered all questions in this category!")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Every question has been used. Reset to start over.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: resetCategory) {
                Text("Reset Questions")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.orange.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Actions

    private func loadState() {
        usedQuestions = storageManager.loadUsedQuestions()
        pickNextQuestion()
    }

    private func pickNextQuestion() {
        currentQuestionIndex = availableIndices.first
    }

    private func skipQuestion() {
        guard let idx = currentQuestionIndex else { return }
        storageManager.markQuestionUsed(categoryId: category.id, questionIndex: idx)
        usedQuestions = storageManager.loadUsedQuestions()
        pickNextQuestion()
    }

    private func resetCategory() {
        var all = storageManager.loadUsedQuestions()
        all.removeAll { $0.categoryId == category.id }
        storageManager.saveUsedQuestions(all)
        usedQuestions = all
        pickNextQuestion()
    }
}

// MARK: - RecordingView stub (placeholder if not yet created)

// Only define if no other RecordingView exists in the module.
// This avoids redeclaration errors. The real RecordingView should
// accept (question:categoryId:) — update as needed.
#if false
struct RecordingView: View {
    let question: String
    let categoryId: String
    var body: some View {
        Text("Recording: \(question)")
    }
}
#endif

#Preview {
    NavigationStack {
        QuestionView(category: QuestionBank.categories[0])
    }
}
