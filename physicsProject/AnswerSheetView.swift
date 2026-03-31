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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("答题卡")
                .font(.title2.bold())
                .padding(.top)
                .padding(.horizontal)

            HStack(spacing: 16) {
                legendItem(title: "未作答", fill: Color.gray.opacity(0.4), stroke: .clear)
                if showsScoring {
                    legendItem(title: "答对", fill: .green, stroke: .clear)
                    legendItem(title: "答错", fill: .red, stroke: .clear)
                } else {
                    legendItem(title: "已作答", fill: .blue, stroke: .clear)
                }
                legendItem(title: "当前题", fill: .clear, stroke: .blue)
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
                                .font(.system(size: 22, weight: .medium))
                                .frame(width: 52, height: 52)
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
