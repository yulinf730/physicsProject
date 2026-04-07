//
//  PaperListView.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/10/21.
//

import SwiftUI

/// 2nd level: show papers within a selected base year (e.g. all "2024 ... Paper ..")
struct PaperListView: View {
    let questions: [Question]
    let mode: QuizMode
    let selectedBaseYear: String
    @Binding var yearProgress: [String: Int]

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var columns: [GridItem] {
        isPad
            ? [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)]
            : [GridItem(.flexible())]
    }

    private func baseYear(from full: String) -> String? {
        if let range = full.range(of: #"^\d{4}"#, options: .regularExpression) {
            return String(full[range])
        }
        return nil
    }

    // 所有属于当前年份的 paper 名称
    private var papers: [String] {
        Array(
            Set(
                questions
                    .filter { baseYear(from: $0.year) == selectedBaseYear }
                    .map { $0.year }
            )
        )
        .sorted(by: >)
    }

    private func answeredCount(for paper: String, questionCount: Int) -> Int {
        guard let saved = QuizProgressStore.shared.load(title: paper, modeRaw: String(describing: mode)),
              saved.answers.count == questionCount else {
            return 0
        }

        return saved.answers.reduce(into: 0) { count, answer in
            if let answer, !answer.isEmpty {
                count += 1
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text(selectedBaseYear)
                        .font(.system(size: isPad ? 42 : 34, weight: .bold))

                    Text("Choose a paper to continue or start")
                        .font(isPad ? .title3 : .subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(papers, id: \.self) { paper in
                        let paperQuestions = questions.filter { $0.year == paper }
                        let questionCount = paperQuestions.count
                        let answeredQuestionCount = answeredCount(for: paper, questionCount: questionCount)

                        NavigationLink {
                            QuizPageView(
                                questions: paperQuestions,
                                mode: mode,
                                title: paper,
                                paperName: paper,
                                yearProgress: $yearProgress,
                                onQuizCompleted: {
                                    yearProgress[paper] = questionCount
                                }
                            )
                        } label: {
                            PaperCard(
                                title: paper,
                                answeredCount: answeredQuestionCount,
                                questionCount: questionCount
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: isPad ? 960 : .infinity)
                .padding(.horizontal, 16)

                Spacer(minLength: 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.12),
                    Color.purple.opacity(0.10),
                    Color.pink.opacity(0.06)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private struct PaperCard: View {
    let title: String
    let answeredCount: Int
    let questionCount: Int

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var statusText: String {
        if questionCount == 0 {
            return "No questions"
        } else if answeredCount == 0 {
            return "Not started"
        } else if answeredCount >= questionCount {
            return "Completed"
        } else if answeredCount == 1 {
            return "1 question answered"
        } else {
            return "\(answeredCount) questions answered"
        }
    }

    private var answeredSummaryText: String {
        if questionCount == 1 {
            return "\(answeredCount) of 1 question answered"
        } else {
            return "\(answeredCount) of \(questionCount) questions answered"
        }
    }

    private var statusColor: Color {
        if questionCount == 0 {
            return .gray
        } else if answeredCount == 0 {
            return .gray
        } else if answeredCount >= questionCount {
            return .green
        } else {
            return .blue
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.18), Color.blue.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: answeredCount >= questionCount && questionCount > 0 ? "checkmark.seal.fill" : "doc.text")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(answeredCount >= questionCount && questionCount > 0 ? .green : .purple)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(isPad ? .title3.weight(.semibold) : .headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Text(statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(statusColor)

                ProgressView(value: Double(answeredCount), total: Double(max(questionCount, 1)))
                    .progressViewStyle(.linear)
                    .tint(answeredCount >= questionCount && questionCount > 0 ? .green : .blue)

                Text(answeredSummaryText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.8))
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.vertical, isPad ? 20 : 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
