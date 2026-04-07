
import SwiftUI

// 1. 包装类型
struct SheetIndex: Identifiable {
    let id: Int
}

struct QuestionReviewCard: View {
    let question: Question
    let answer: String?
    let index: Int
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

            Text("Q\(index + 1)")
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
                ScoreSummaryCard(title: "Correct", value: correct, tint: .green)
                ScoreSummaryCard(title: "Wrong", value: wrong, tint: .red)
                ScoreSummaryCard(title: "Undone", value: undone, tint: .orange)
                ScoreSummaryCard(title: "Total", value: total, tint: .blue)
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

    var body: some View {
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
                .fill(tint.opacity(0.10))
        )
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

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                ScoreHeaderView(correct: correct, wrong: wrong, undone: undone, total: total)

                if showsActionButtons {
                    ResultActionRow(onRestart: onRestart, onBack: onBack)
                }

                ForEach(questions.indices, id: \.self) { idx in
                    QuestionReviewCard(
                        question: questions[idx],
                        answer: userAnswers[idx],
                        index: idx,
                        onTap: {
                            selectedSheetIndex = SheetIndex(id: idx)
                        }
                    )
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
