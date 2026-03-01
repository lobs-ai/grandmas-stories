import SwiftUI

@main
struct GrandmasStoriesApp: App {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var permissionManager = PermissionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .environmentObject(permissionManager)
        }
    }
}
