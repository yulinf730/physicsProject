import Foundation

struct QuizProgress: Codable {
    let title: String
    let modeRaw: String
    let questionIDs: [String]
    let currentIndex: Int
    let answers: [String?]
}

extension QuizProgress {
    static func blank(title: String, mode: QuizMode, questionCount: Int, questionIDs: [String]) -> QuizProgress {
        QuizProgress(
            title: title,
            modeRaw: String(describing: mode),
            questionIDs: questionIDs,
            currentIndex: 0,
            answers: Array(repeating: nil, count: questionCount)
        )
    }

    func matches(_ questions: [Question]) -> Bool {
        answers.count == questions.count && questionIDs == questions.map(\.id)
    }

    var clampedCurrentIndex: Int {
        min(currentIndex, max(answers.count - 1, 0))
    }
}

struct QuizScoreSummary {
    let correct: Int
    let wrong: Int
    let undone: Int
    let total: Int

    init(questions: [Question], answers: [String?]) {
        var correct = 0
        var wrong = 0
        var undone = 0

        for (question, answer) in zip(questions, answers) {
            guard let answer, !answer.isEmpty else {
                undone += 1
                continue
            }

            if answer == question.answer {
                correct += 1
            } else {
                wrong += 1
            }
        }

        self.correct = correct
        self.wrong = wrong
        self.undone = undone
        self.total = questions.count
    }

    func makeHistoryRecord(title: String, questions: [Question], answers: [String?], mode: QuizMode) -> QuizHistoryRecord {
        QuizHistoryRecord(
            id: UUID(),
            date: Date(),
            title: title,
            total: total,
            correct: correct,
            undone: undone,
            wrong: wrong,
            userAnswers: answers,
            questions: questions,
            mode: mode
        )
    }
}

enum QuizProgressCalculator {
    static func completedQuestionCount(questionCount: Int, currentIndex: Int, answers: [String?]) -> Int {
        guard questionCount > 0 else { return 0 }

        let answeredCount = answers.filter { answer in
            guard let answer else { return false }
            return !answer.isEmpty
        }.count

        let visibleProgress = min(currentIndex + 1, questionCount)
        return min(max(answeredCount, visibleProgress), questionCount)
    }
}
