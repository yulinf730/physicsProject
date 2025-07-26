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
                .font(.callout)
                .foregroundColor(.blue)

            Text(question.explanation)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
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

    var body: some View {
        VStack(spacing: 12) {
            Text("🎉 Completed！")
                .font(.largeTitle)
                .padding(.top, 16)

            Text("✅ Correct: \(correct)   ❌ Wrong: \(wrong)")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            Text("⏸ Undone: \(undone)   🔢 Total: \(total)")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Divider().padding(.bottom, 6)
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

    @State private var selectedSheetIndex: SheetIndex? = nil

    var body: some View {
        VStack(spacing: 12) {
            ScoreHeaderView(correct: correct, wrong: wrong, undone: undone, total: total)

            ScrollView {
                VStack(spacing: 28) {
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
            }
            .padding(.top, 8)
            .padding(.vertical, 10)
        }
        .padding()
        .sheet(item: $selectedSheetIndex) { sheetIndex in
            QuestionView(
                question: questions[sheetIndex.id],
                mode: .practice,
                onAnswered: { _ in }
            )
        }
    }
}
