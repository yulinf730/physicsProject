import Foundation

final class QuizProgressStore {
    static let shared = QuizProgressStore()

    private init() {}

    private func key(title: String, modeRaw: String) -> String {
        "quiz_progress_\(title)_\(modeRaw)"
    }

    func save(_ progress: QuizProgress) {
        do {
            let data = try JSONEncoder().encode(progress)
            let saveKey = key(title: progress.title, modeRaw: progress.modeRaw)
            UserDefaults.standard.set(data, forKey: saveKey)

            print("✅ Saved progress")
            print("   key =", saveKey)
            print("   currentIndex =", progress.currentIndex)
            print("   answers =", progress.answers)
        } catch {
            print("❌ Failed to save progress:", error)
        }
    }

    func load(title: String, modeRaw: String) -> QuizProgress? {
        let saveKey = key(title: title, modeRaw: modeRaw)

        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            print("ℹ️ No saved progress for key =", saveKey)
            return nil
        }

        do {
            let progress = try JSONDecoder().decode(QuizProgress.self, from: data)
            print("✅ Loaded progress")
            print("   key =", saveKey)
            print("   currentIndex =", progress.currentIndex)
            print("   answers =", progress.answers)
            return progress
        } catch {
            print("❌ Failed to load progress:", error)
            return nil
        }
    }

    func clear(title: String, modeRaw: String) {
        let saveKey = key(title: title, modeRaw: modeRaw)
        UserDefaults.standard.removeObject(forKey: saveKey)
        print("🗑 Cleared progress for key =", saveKey)
    }
}
