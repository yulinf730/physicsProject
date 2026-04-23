
import SwiftUI

struct SheetIndex: Identifiable {
    let id: Int
}

enum ReviewFilter: String {
    case all
    case correct
    case wrong
    case undone

    func includes(question: Question, answer: String?) -> Bool {
        switch self {
        case .all:
            return true
        case .correct:
            guard let answer, !answer.isEmpty else { return false }
            return answer == question.answer
        case .wrong:
            guard let answer, !answer.isEmpty else { return false }
            return answer != question.answer
        case .undone:
            guard let answer else { return true }
            return answer.isEmpty
        }
    }

    static func visibleIndices(questions: [Question], answers: [String?], filter: ReviewFilter) -> [Int] {
        questions.indices.filter { index in
            let answer = answers.indices.contains(index) ? answers[index] : nil
            return filter.includes(question: questions[index], answer: answer)
        }
    }
}

struct QuestionReviewCard: View {
    let question: Question
    let answer: String?
    var onTap: (() -> Void)? = nil

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        let isAnswered = (answer ?? "").isEmpty == false
        let isCorrect = isAnswered && answer == question.answer

        VStack(alignment: .leading, spacing: 10) {
            if let uiImage = UIImage(named: question.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .cornerRadius(8)
            }

            Text("Q\(question.questionNumber)")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 16) {
                ForEach(question.options, id: \.self) { opt in
                    Text(opt)
                        .font(.title3)
                        .fontWeight(.medium)
                        .frame(width: 44, height: 44)
                        .background(
                            answer == opt
                                ? (isCorrect ? Color.green.opacity(0.5) : Color.red.opacity(0.5))
                                : Color(.systemGray5)
                        )
                        .foregroundColor(
                            answer == opt ? .white : .primary
                        )
                        .clipShape(Circle())
                }
            }

            Text("Answer: \(question.answer)")
                .font(isPad ? .title3.weight(.semibold) : .callout)
                .foregroundColor(.blue)

            Text(question.explanation)
                .font(isPad ? .body : .footnote)
                .foregroundColor(.secondary)
                .lineSpacing(isPad ? 4 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            isAnswered ?
                (isCorrect ? Color(.systemGray6) : Color.red.opacity(0.08))
                : Color(.systemGray6)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isAnswered ?
                        (isCorrect ? Color.green.opacity(0.3) : Color.red)
                        : Color.gray.opacity(0.3),
                    lineWidth: isAnswered ? (isCorrect ? 1 : 2) : 1
                )
        )
        .onTapGesture { onTap?() }
    }
}

struct ScoreHeaderView: View {
    let correct: Int
    let wrong: Int
    let undone: Int
    let total: Int
    let selectedFilter: ReviewFilter
    let onFilterSelected: (ReviewFilter) -> Void

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var summaryColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: isPad ? 150 : 132, maximum: isPad ? 190 : 180),
                spacing: 12
            )
        ]
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Completed")
                .font(isPad ? .largeTitle.bold() : .title.bold())
                .padding(.top, 16)

            Text("Review your answers below.")
                .font(isPad ? .title3 : .subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: summaryColumns, spacing: 12) {
                ScoreSummaryCard(
                    title: "Correct",
                    value: correct,
                    tint: .green,
                    isSelected: selectedFilter == .correct,
                    action: { onFilterSelected(.correct) }
                )
                ScoreSummaryCard(
                    title: "Wrong",
                    value: wrong,
                    tint: .red,
                    isSelected: selectedFilter == .wrong,
                    action: { onFilterSelected(.wrong) }
                )
                ScoreSummaryCard(
                    title: "Undone",
                    value: undone,
                    tint: .orange,
                    isSelected: selectedFilter == .undone,
                    action: { onFilterSelected(.undone) }
                )
                ScoreSummaryCard(
                    title: "Total",
                    value: total,
                    tint: .blue,
                    isSelected: selectedFilter == .all,
                    action: { onFilterSelected(.all) }
                )
            }
            .padding(.top, 6)

            Divider().padding(.bottom, 6)
        }
    }
}

private struct ScoreSummaryCard: View {
    let title: String
    let value: Int
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Text("\(value)")
                    .font(.title2.bold())
                    .foregroundColor(tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(isSelected ? 0.18 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(isSelected ? 0.70 : 0.0), lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ResultActionRow: View {
    let onRestart: () -> Void
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Text("Back")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button(action: onRestart) {
                Text("Try Again")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

struct ResultView: View {
    let questions: [Question]
    let userAnswers: [String?]
    let correct: Int
    let wrong: Int
    let undone: Int
    let total: Int
    var onRestart: () -> Void
    var onBack: () -> Void
    var showsActionButtons: Bool = true

    @State private var selectedSheetIndex: SheetIndex? = nil
    @State private var selectedFilter: ReviewFilter = .all

    private var visibleQuestionIndices: [Int] {
        ReviewFilter.visibleIndices(
            questions: questions,
            answers: userAnswers,
            filter: selectedFilter
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                ScoreHeaderView(
                    correct: correct,
                    wrong: wrong,
                    undone: undone,
                    total: total,
                    selectedFilter: selectedFilter,
                    onFilterSelected: { filter in
                        selectedFilter = filter
                    }
                )

                if showsActionButtons {
                    ResultActionRow(onRestart: onRestart, onBack: onBack)
                }

                ForEach(visibleQuestionIndices, id: \.self) { idx in
                    QuestionReviewCard(
                        question: questions[idx],
                        answer: userAnswers[idx],
                        onTap: {
                            selectedSheetIndex = SheetIndex(id: idx)
                        }
                    )
                }

                if visibleQuestionIndices.isEmpty {
                    Text("No questions in this filter.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                }
            }
            .padding(.bottom, 32)
            .padding(.top, 8)
            .padding(.vertical, 10)
        }
        .padding()
        .sheet(item: $selectedSheetIndex) { sheetIndex in
            QuestionView(
                question: questions[sheetIndex.id],
                mode: .practice,
                selectedAnswer: userAnswers[sheetIndex.id],
                onAnswered: { _ in }
            )
        }
    }
}
