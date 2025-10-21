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

    @State private var completedPaper: String? = nil

    private func baseYear(from full: String) -> String? {
        if let range = full.range(of: #"^\d{4}"#, options: .regularExpression) {
            return String(full[range])
        }
        return nil
    }

    // Distinct paper labels for the chosen year, sorted desc
    private var papers: [String] {
        Array(
            Set(
                questions
                    .filter { baseYear(from: $0.year) == selectedBaseYear }
                    .map { $0.year }
            )
        ).sorted(by: >)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("\(selectedBaseYear) Papers")
                    .font(.largeTitle.bold())
                    .padding(.top, 8)

                ForEach(papers, id: \.self) { paper in
                    NavigationLink {
                        let qs = questions.filter { $0.year == paper }
                        QuizPageView(
                            questions: qs,
                            mode: mode,
                            title: paper,
                            onQuizCompleted: {
                                // Increment per-paper completion count
                                yearProgress[paper, default: 0] += 1
                                completedPaper = paper
                            }
                        )
                    } label: {
                        PaperCard(
                            title: paper,
                            finishedCount: yearProgress[paper, default: 0],
                            questionCount: questions.filter { $0.year == paper }.count
                        )
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.12)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private struct PaperCard: View {
    let title: String
    let finishedCount: Int
    let questionCount: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text("\(questionCount) question\(questionCount > 1 ? "s" : "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if finishedCount > 0 {
                    Text("Finished \(finishedCount) time\(finishedCount > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Not finished yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 20))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: Color.purple.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
