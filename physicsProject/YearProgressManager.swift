//
//  YearProgressManager.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/7/22.
//
import Foundation

class YearProgressManager: ObservableObject {
    static let shared = YearProgressManager()

    @Published var progress: [String: Int] {
        didSet {
            save()
        }
    }
    
    private let key = "year_progress"
    
    private init() {
        // 从 UserDefaults 加载
        if let data = UserDefaults.standard.data(forKey: key),
           let dict = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.progress = dict
        } else {
            self.progress = [:]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clampedProgress(for key: String, total: Int) -> Int {
        min(max(progress[key] ?? 0, 0), total)
    }
}
