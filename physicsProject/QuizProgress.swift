import Foundation

struct QuizProgress: Codable {
    let title: String
    let modeRaw: String
    let questionIDs: [String]
    let currentIndex: Int
    let answers: [String?]
}
