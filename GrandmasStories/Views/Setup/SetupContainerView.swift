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
}
