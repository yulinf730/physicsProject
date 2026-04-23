//
//  physicsProjectTests.swift
//  physicsProjectTests
//
//  Created by Yulin Feng on 2025/7/20.
//

import Testing
@testable import physicsProject

struct physicsProjectTests {
    private let sampleQuestions = [
        Question(
            id: "q1",
            topic: "Mechanics",
            year: "2024 Paper 1",
            imageName: "q1",
            options: ["A", "B", "C", "D"],
            answer: "A",
            explanation: "Because A is correct."
        ),
        Question(
            id: "q2",
            topic: "Electricity",
            year: "2024 Paper 1",
            imageName: "q2",
            options: ["A", "B", "C", "D"],
            answer: "C",
            explanation: "Because C is correct."
        ),
        Question(
            id: "q3",
            topic: "Waves",
            year: "2024 Paper 1",
            imageName: "q3",
            options: ["A", "B", "C", "D"],
            answer: "D",
            explanation: "Because D is correct."
        )
    ]

    @Test func quizProgressMatchesCurrentQuestionSet() async throws {
        let progress = QuizProgress(
            title: "2024 Paper 1",
            modeRaw: QuizMode.practice.rawValue,
            questionIDs: sampleQuestions.map(\.id),
            currentIndex: 1,
            answers: ["A", nil, nil]
        )

        #expect(progress.matches(sampleQuestions))
        #expect(progress.clampedCurrentIndex == 1)
    }

    @Test func quizProgressRejectsChangedQuestionSet() async throws {
        let progress = QuizProgress(
            title: "2024 Paper 1",
            modeRaw: QuizMode.practice.rawValue,
            questionIDs: ["q1", "q9", "q3"],
            currentIndex: 1,
            answers: ["A", nil, nil]
        )

        #expect(!progress.matches(sampleQuestions))
    }

    @Test func quizScoreSummaryCountsCorrectWrongAndUndone() async throws {
        let summary = QuizScoreSummary(
            questions: sampleQuestions,
            answers: ["A", "B", nil]
        )

        #expect(summary.correct == 1)
        #expect(summary.wrong == 1)
        #expect(summary.undone == 1)
        #expect(summary.total == 3)
    }

    @Test func completedQuestionCountUsesAnsweredOrVisibleProgress() async throws {
        let answers: [String?] = ["A", nil, nil, nil]

        let progressAtStart = QuizProgressCalculator.completedQuestionCount(
            questionCount: 4,
            currentIndex: 0,
            answers: answers
        )
        let progressAfterJump = QuizProgressCalculator.completedQuestionCount(
            questionCount: 4,
            currentIndex: 2,
            answers: answers
        )

        #expect(progressAtStart == 1)
        #expect(progressAfterJump == 3)
    }

    @Test func completedQuestionCountIsClampedToQuestionTotal() async throws {
        let answers: [String?] = ["A", "B", "C"]

        let progress = QuizProgressCalculator.completedQuestionCount(
            questionCount: 2,
            currentIndex: 5,
            answers: answers
        )

        #expect(progress == 2)
    }

    @Test func reviewFilterShowsOnlyWrongQuestions() async throws {
        let visibleIndices = ReviewFilter.visibleIndices(
            questions: sampleQuestions,
            answers: ["A", "B", nil],
            filter: .wrong
        )

        #expect(visibleIndices == [1])
    }

    @Test func reviewFilterCanReturnAllQuestions() async throws {
        let visibleIndices = ReviewFilter.visibleIndices(
            questions: sampleQuestions,
            answers: ["A", "B", nil],
            filter: .all
        )

        #expect(visibleIndices == [0, 1, 2])
    }
}
