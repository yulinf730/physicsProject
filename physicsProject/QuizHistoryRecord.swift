import SwiftUI
import Foundation

struct QuizHistoryRecord: Codable,Identifiable, Hashable {
    let id: UUID
    let date: Date
    let title: String
    let total: Int
    let correct: Int
    let undone: Int
    let wrong: Int
    let userAnswers: [String?]
    let questions: [Question]
    let mode: QuizMode
}
