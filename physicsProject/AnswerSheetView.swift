//
//  AnswerSheetView.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/10/21.
//

import SwiftUI

enum AnswerSheetDisplayMode {
    case progressOnly
    case scored(correctAnswers: [String])
}

struct AnswerSheetView: View {
    let total: Int
    let answers: [String?]
    let onSelect: (Int) -> Void
    var currentIndex: Int = -1
    let displayMode: AnswerSheetDisplayMode

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: isPad ? 64 : 52, maximum: isPad ? 86 : 68),
                spacing: 16
            )
        ]
    }

    private var answeredCount: Int {
        answers.filter { answer in
            guard let answer else { return false }
            return !answer.isEmpty
        }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Answer Sheet")
                .font(.title2.bold())
                .padding(.top)
                .padding(.horizontal)

            Text("\(answeredCount) of \(total) answered")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: isPad ? 120 : 108), spacing: 12)],
                alignment: .leading,
                spacing: 10
            ) {
                legendItem(title: "Unanswered", fill: Color.gray.opacity(0.4), stroke: .clear)
                if showsScoring {
                    legendItem(title: "Correct", fill: .green, stroke: .clear)
                    legendItem(title: "Wrong", fill: .red, stroke: .clear)
                } else {
                    legendItem(title: "Answered", fill: .blue, stroke: .clear)
                }
                legendItem(title: "Current", fill: .clear, stroke: .blue)
            }
            .font(.caption)
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<total, id: \.self) { index in
                        let userAnswer = index < answers.count ? answers[index] : nil
                        let isCurrent = index == currentIndex

                        Button(action: {
                            onSelect(index)
                        }) {
                            Text("\(index + 1)")
                                .font(.system(size: isPad ? 24 : 22, weight: .medium))
                                .frame(width: isPad ? 60 : 52, height: isPad ? 60 : 52)
                                .background(backgroundColor(index: index, userAnswer: userAnswer))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(
                                        isCurrent ? Color.blue : Color.clear,
                                        lineWidth: 3
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: isPad ? 760 : .infinity, alignment: .leading)
                .padding()
            }

            Spacer()
        }
    }

    private var showsScoring: Bool {
        if case .scored = displayMode {
            return true
        }
        return false
    }

    private func legendItem(title: String, fill: Color, stroke: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(fill)
                .overlay(
                    Circle().stroke(stroke, lineWidth: 2)
                )
                .frame(width: 14, height: 14)

            Text(title)
        }
    }

    private func backgroundColor(index: Int, userAnswer: String?) -> Color {
        guard let userAnswer, !userAnswer.isEmpty else {
            return Color.gray.opacity(0.4)
        }

        switch displayMode {
        case .progressOnly:
            return .blue
        case .scored(let correctAnswers):
            let correctAnswer = index < correctAnswers.count ? correctAnswers[index] : ""
            return userAnswer == correctAnswer ? .green : .red
        }
    }
}
