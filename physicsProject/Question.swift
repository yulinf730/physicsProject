import Foundation

struct Question: Identifiable, Codable, Equatable,Hashable {
    let id: String
    let topic: String
    let year: String
    let imageName: String
    let options: [String]
    let answer: String
    let explanation: String
}
