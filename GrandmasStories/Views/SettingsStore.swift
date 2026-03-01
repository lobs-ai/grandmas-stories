import SwiftUI
import Combine

/// Observable wrapper around StorageManager for SwiftUI bindings.
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: AppSettings

    private let storage: StorageManager

    init(storage: StorageManager = StorageManager()) {
        self.storage = storage
        self.settings = storage.loadSettings()
    }

    func save(_ settings: AppSettings) {
        self.settings = settings
        storage.saveSettings(settings)
    }
}
