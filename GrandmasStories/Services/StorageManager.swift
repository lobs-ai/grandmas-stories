import Foundation

/// Handles all persistence: settings, used questions, and audio files.
final class StorageManager: ObservableObject {

    // MARK: - Keys

    private enum Keys {
        static let appSettings = "appSettings"
        static let usedQuestions = "usedQuestions"
    }

    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
    }

    // MARK: - Documents Directory

    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var audioDirectory: URL {
        documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
    }

    // MARK: - AppSettings

    func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: Keys.appSettings),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        userDefaults.set(data, forKey: Keys.appSettings)
    }

    // MARK: - UsedQuestions

    func loadUsedQuestions() -> [UsedQuestion] {
        guard let data = userDefaults.data(forKey: Keys.usedQuestions),
              let questions = try? decoder.decode([UsedQuestion].self, from: data) else {
            return []
        }
        return questions
    }

    func saveUsedQuestions(_ questions: [UsedQuestion]) {
        guard let data = try? encoder.encode(questions) else { return }
        userDefaults.set(data, forKey: Keys.usedQuestions)
    }

    func markQuestionUsed(categoryId: String, questionIndex: Int) {
        var questions = loadUsedQuestions()
        let used = UsedQuestion(categoryId: categoryId, questionIndex: questionIndex)
        questions.append(used)
        saveUsedQuestions(questions)
    }

    // MARK: - Audio Files

    /// Ensures the Recordings directory exists.
    func ensureAudioDirectoryExists() throws {
        if !fileManager.fileExists(atPath: audioDirectory.path) {
            try fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        }
    }

    /// Returns URL for a given fileName within the audio directory.
    func audioFileURL(fileName: String) -> URL {
        audioDirectory.appendingPathComponent(fileName)
    }

    /// Saves audio data to Documents/Recordings/. Returns the file URL.
    @discardableResult
    func saveAudioFile(data: Data, fileName: String) throws -> URL {
        try ensureAudioDirectoryExists()
        let url = audioFileURL(fileName: fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Deletes an audio file by fileName.
    func deleteAudioFile(fileName: String) throws {
        let url = audioFileURL(fileName: fileName)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    /// Lists all recordings (audio files) in Documents/Recordings/.
    func listRecordingFileNames() throws -> [String] {
        try ensureAudioDirectoryExists()
        let contents = try fileManager.contentsOfDirectory(atPath: audioDirectory.path)
        return contents.sorted()
    }

    /// File size in bytes for a given fileName.
    func fileSize(fileName: String) -> Int64 {
        let url = audioFileURL(fileName: fileName)
        let attrs = try? fileManager.attributesOfItem(atPath: url.path)
        return (attrs?[.size] as? Int64) ?? 0
    }

    // MARK: - Recording Metadata

    private enum RecordingKeys {
        static let recordings = "recordings"
    }

    func loadRecordings() -> [Recording] {
        guard let data = userDefaults.data(forKey: RecordingKeys.recordings),
              let recordings = try? decoder.decode([Recording].self, from: data) else {
            return []
        }
        return recordings
    }

    func saveRecording(_ recording: Recording) {
        var recordings = loadRecordings()
        if let idx = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[idx] = recording
        } else {
            recordings.append(recording)
        }
        guard let data = try? encoder.encode(recordings) else { return }
        userDefaults.set(data, forKey: RecordingKeys.recordings)
    }

    func saveRecordings(_ recordings: [Recording]) {
        guard let data = try? encoder.encode(recordings) else { return }
        userDefaults.set(data, forKey: RecordingKeys.recordings)
    }
}
