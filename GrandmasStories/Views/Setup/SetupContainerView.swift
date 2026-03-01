import SwiftUI

/// Container that manages the multi-step setup flow.
struct SetupContainerView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    @State private var currentStep: Int = 0

    private let totalSteps = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .tint(.purple)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            RecordingTestView(onContinue: advance)
        case 1:
            // Placeholder for future step 2 (e.g., profile setup)
            placeholderStep(
                icon: "person.circle.fill",
                title: "Tell us about yourself",
                subtitle: "We'll personalize your experience.",
                buttonTitle: "Next"
            )
        default:
            // Final step — complete setup
            placeholderStep(
                icon: "checkmark.circle.fill",
                title: "You're all set!",
                subtitle: "Start recording your first story.",
                buttonTitle: "Get Started"
            )
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Microphone Test"
        case 1: return "Your Profile"
        default: return "Ready!"
        }
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation {
            if currentStep < totalSteps - 1 {
                currentStep += 1
            } else {
                completeSetup()
            }
        }
    }

    private func completeSetup() {
        var updated = settingsStore.settings
        updated.hasCompletedSetup = true
        settingsStore.save(updated)
    }

    // MARK: - Placeholder Step

    private func placeholderStep(
        icon: String,
        title: String,
        subtitle: String,
        buttonTitle: String
    ) -> some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(.purple)

            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: advance) {
                Text(buttonTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
