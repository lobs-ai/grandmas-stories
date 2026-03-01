import SwiftUI

@main
struct GrandmasStoriesApp: App {
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
        }
    }
}
