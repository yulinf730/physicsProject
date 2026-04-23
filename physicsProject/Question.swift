import Foundation

struct Question: Identifiable, Codable, Equatable,Hashable {
    let id: String
    let topic: String
    let year: String
    let imageName: String
    let options: [String]
    let answer: String
    let explanation: String

    var displayTopic: String {
        topic
    }

    var questionNumber: Int {
        let patterns = [id, imageName]

        for pattern in patterns {
            guard let match = pattern.range(of: #"Q(\d+)$"#, options: .regularExpression) else {
                continue
            }

            let suffix = String(pattern[match]).dropFirst()
            if let number = Int(suffix) {
                return number
            }
        }

        return Int.max
    }

    static func sortedForPaper(_ questions: [Question]) -> [Question] {
        questions.sorted {
            if $0.questionNumber == $1.questionNumber {
                return $0.id < $1.id
            }
            return $0.questionNumber < $1.questionNumber
        }
    }
}
