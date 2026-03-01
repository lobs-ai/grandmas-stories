import SwiftUI

/// Container that manages the multi-step setup flow.
struct SetupContainerView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    @State private var currentStep: Int = 0

    private let totalSteps = 2

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .tint(AppColors.warmOrange)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .accessibilityLabel("Step \(currentStep + 1) of \(totalSteps)")
                .accessibilityValue("\(Int((Double(currentStep + 1) / Double(totalSteps)) * 100)) percent complete")

            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            RecordingTestView(onContinue: advance)
        default:
            FamilySharingSetupView(onFinish: completeSetup)
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Microphone Test"
        default: return "Family & Sharing"
        }
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(.easeInOut(duration: 0.3)) {
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
}
