//
//  YearGroupListView.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/10/21.
//


import SwiftUI

/// 1st level: show distinct years (e.g. 2024, 2023). Tap to see papers of that year.
struct YearGroupListView: View {
    let questions: [Question]
    let mode: QuizMode
    @Binding var yearProgress: [String: Int]

    // Extract leading 4-digit year like "2024" from Question.year (e.g. "2024 May Paper 22")
    private func baseYear(from full: String) -> String? {
        if let range = full.range(of: #"^\d{4}"#, options: .regularExpression) {
            return String(full[range])
        }
        return nil
    }

    // Group all questions by base year
    private var groupedByYear: [String: [Question]] {
        Dictionary(grouping: questions) { q in
            baseYear(from: q.year) ?? "Other"
        }
    }

    // Sorted list of base years (desc)
    private var baseYears: [String] {
        groupedByYear.keys.sorted(by: >)
    }

    private func answeredCount(for paperName: String, questionCount: Int) -> Int {
        guard let saved = QuizProgressStore.shared.load(title: paperName, modeRaw: String(describing: mode)),
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
                Text("Choose Year")
                    .font(.largeTitle.bold())
                    .padding(.top, 8)

                ForEach(baseYears, id: \.self) { y in
                    let papersInYear = Dictionary(grouping: groupedByYear[y] ?? [], by: \.year)
                    let finishedPapers = papersInYear.values.filter { paperQuestions in
                        guard let paperName = paperQuestions.first?.year else { return false }
                        let completedCount = answeredCount(for: paperName, questionCount: paperQuestions.count)
                        return completedCount >= paperQuestions.count
                    }.count

                    NavigationLink {
                        PaperListView(
                            questions: questions,
                            mode: mode,
                            selectedBaseYear: y,
                            yearProgress: $yearProgress
                        )
                    } label: {
                        YearGroupCard(
                            baseYear: y,
                            paperCount: papersInYear.count,
                            finishedPaperCount: finishedPapers
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

private struct YearGroupCard: View {
    let baseYear: String
    let paperCount: Int
    let finishedPaperCount: Int

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: "calendar")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 6) {
                Text(baseYear)
                    .font(.title2).fontWeight(.semibold)

                Text("\(paperCount) paper\(paperCount > 1 ? "s" : "") in \(baseYear)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if paperCount > 0 {
                    ProgressView(value: Double(finishedPaperCount), total: Double(paperCount))
                        .progressViewStyle(.linear)
                        .frame(width: 160)

                    Text("Completed \(finishedPaperCount)/\(paperCount)")
                        .font(.caption)
                        .foregroundColor(finishedPaperCount > 0 ? .green : .gray)
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
        .cornerRadius(20)
        .shadow(color: Color.blue.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
