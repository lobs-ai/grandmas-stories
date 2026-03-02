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
                    .accessibilityLabel("Loading question")
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
                .foregroundStyle(AppColors.warmOrange)
                .accessibilityHidden(true)

            Text(question)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            VStack(spacing: 14) {
                NavigationLink(destination: RecordingView(question: question, categoryId: category.id)) {
                    Label("Start Recording", systemImage: "mic.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(AppColors.warmOrange.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start recording your answer")
                .accessibilityHint("Tap to begin recording a response to this question")

                Button(action: skipQuestion) {
                    Label("Skip Question", systemImage: "forward.fill")
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppColors.warmOrange)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(AppColors.warmOrange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Skip this question")
                .accessibilityHint("Move to the next available question in this category")
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
                .accessibilityLabel("Celebration emoji")

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
                    .background(AppColors.warmOrange.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .accessibilityLabel("Reset all questions in this category")
            .accessibilityHint("You will be able to record answers to all questions again")
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

#Preview {
    NavigationStack {
        QuestionView(category: QuestionBank.categories[0])
    }
}
