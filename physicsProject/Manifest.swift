import Foundation

struct Manifest: Codable {
    let version: Int
    let updatedAt: Date
    let questions: [Question]
}

struct Question: Codable, Identifiable, Hashable {
    let id: String
    let topic: String
    let text: String
    let imageURL: URL?
    let choices: [String]
    let correctIndex: Int
    let explanation: String?
    let tags: [String]?
    let updatedAt: Date
}
