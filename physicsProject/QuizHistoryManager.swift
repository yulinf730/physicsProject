//
//  QuizHistoryManager.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/7/22.
//
import Foundation
class QuizHistoryManager: ObservableObject {
    static let shared = QuizHistoryManager()
    @Published var records: [QuizHistoryRecord] = []


    private let saveKey = "quizHistoryRecords"

    private init() { load() }
    

    func add(_ record: QuizHistoryRecord) {
        records.append(record)
        save()
    }

    func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    func delete(at offsets: IndexSet) {
            records.remove(atOffsets: offsets)
            save() // 如果有本地存储
        }

    func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode([QuizHistoryRecord].self, from: data) {
            records = saved
        }
    }
}

