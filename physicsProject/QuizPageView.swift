import SwiftUI
import Foundation

struct QuizPageView: View {
    @Environment(\.dismiss) private var dismiss
    let questions: [Question]
    let mode: QuizMode
    @State private var currentIndex = 0
    @State private var answers: [String?]
    @State private var showResult = false
    @State private var correctCount = 0
    @State private var wrongCount = 0
    @State private var canGoNext = false
    var onQuizCompleted: (() -> Void)? = nil
    // 增加一个标记是否已完成
    @State private var didCompleted = false
    let title: String  //增加试卷名称

    init(questions: [Question], mode: QuizMode,title: String, onQuizCompleted: (() -> Void)? = nil) {
        self.questions = questions
        self.mode = mode
        self.title = title
        self.onQuizCompleted = onQuizCompleted
        _answers = State(initialValue: Array(repeating: nil, count: questions.count))
    }

    var body: some View {
        if showResult {
            ResultView(
                questions: questions,
                userAnswers: answers,
                correct: correctCount,
                wrong: wrongCount,
                total: questions.count,
                onRestart: {
                    answers = Array(repeating: nil, count: questions.count)
                    correctCount = 0
                    wrongCount = 0
                    currentIndex = 0
                    showResult = false
                    didCompleted = false
                },
                onBack: {
                    dismiss()
                }
            )
            .onDisappear {
                // 只在返回时调用闭包，且只调用一次
                if didCompleted == false {
                    didCompleted = true
                    onQuizCompleted?()
                }
            }
        } else {
            ZStack {
                VStack {
                    Text("Question \(currentIndex + 1)/\(questions.count)")
                    TabView(selection: $currentIndex) {
                        ForEach(questions.indices, id: \.self) { i in
                            QuestionView(
                                question: questions[i],
                                mode: mode,
                                onAnswered: { selected in
                                    answers[i] = selected
                                    canGoNext = true
                                }
                            )
                            .tag(i)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .animation(.spring(), value: currentIndex)
                    .onChange(of: currentIndex) { _ in
                        canGoNext = false
                    }
                    HStack {
                        Button("上一题") { if currentIndex > 0 { currentIndex -= 1 } }
                            .disabled(currentIndex == 0)
                        Button("下一题") { if currentIndex < questions.count - 1 { currentIndex += 1 } }
                            .disabled(currentIndex == questions.count - 1)
                    }
                    .padding()

                    if currentIndex == questions.count - 1 {
                        Button("提交") {
                            submitQuiz()
                            showResult = true
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding()
                    }
                }
            }
        }
    }

    func submitQuiz() {
        var correct = 0
        var wrong = 0
        for (i, ans) in answers.enumerated() {
            if ans == questions[i].answer {
                correct += 1
            } else {
                wrong += 1
                WrongQuestionManager.shared.addWrongQuestion(id: questions[i].id, selectedAnswer: ans ?? "")
            }
        }
        correctCount = correct
        wrongCount = wrong

        QuizHistoryManager.shared.add(
            QuizHistoryRecord(
                id: UUID(),
                date: Date(),
                title: title,   // 这里用传进来的 title
                total: questions.count,
                correct: correct,
                wrong: wrong,
                userAnswers: answers,
                questions: questions,
                mode: mode
            )
        )
        // ⚠️ 不再此处直接调用 onQuizCompleted
    }
}
