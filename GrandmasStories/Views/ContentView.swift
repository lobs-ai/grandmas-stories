import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        if settingsStore.settings.hasCompletedSetup {
            HomeView()
        } else {
            SetupContainerView()
        }
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    var body: some View {
        NavigationStack {
            Text("Welcome to Grandma's Stories")
                .navigationTitle("Stories")
        }
    }
}

struct SetupView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple)

                Text("Grandma's Stories")
                    .font(.largeTitle.bold())

                Text("Record and share personal family stories.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("Get Started") {
                    var updated = settingsStore.settings
                    updated.hasCompletedSetup = true
                    settingsStore.save(updated)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Welcome")
        }
    }
}
