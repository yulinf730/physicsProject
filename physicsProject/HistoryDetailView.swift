//
//  HistoryDetailView.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/7/22.
//
import SwiftUI

struct HistoryDetailView: View {
    let record: QuizHistoryRecord
    var body: some View {
        ResultView(
            questions: record.questions,
            userAnswers: record.userAnswers,
            correct: record.correct,
            wrong: record.wrong,
            undone: record.undone,
            total: record.total,
            onRestart: {},
            onBack: {},
            showsActionButtons: false
        )
    }
}
