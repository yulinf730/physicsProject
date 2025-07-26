import SwiftUI
import Foundation

struct QuizPageView: View {
    @Environment(\.dismiss) private var dismiss
    let questions: [Question]
    let mode: QuizMode
    let title: String  // 试卷名称

    @State private var currentIndex = 0
    @State private var answers: [String?]
    @State private var showResult = false
    @State private var correctCount = 0
    @State private var wrongCount = 0
    @State private var undoneCount = 0
    @State private var canGoNext = false
    @State private var didCompleted = false  // 是否已完成提交
    var onQuizCompleted: (() -> Void)? = nil

    init(questions: [Question], mode: QuizMode, title: String, onQuizCompleted: (() -> Void)? = nil) {
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
                undone: undoneCount,
                total: questions.count,
                onRestart: {
                    answers = Array(repeating: nil, count: questions.count)
                    correctCount = 0
                    wrongCount = 0
                    undoneCount = 0
                    currentIndex = 0
                    showResult = false
                    didCompleted = false
                },
                onBack: {
                    dismiss()
                }
            )
            .onDisappear {
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
                        Button("上一题") {
                            if currentIndex > 0 {
                                currentIndex -= 1
                            }
                        }
                        .disabled(currentIndex == 0)

                        Button("下一题") {
                            if currentIndex < questions.count - 1 {
                                currentIndex += 1
                            }
                        }
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
        var undone = 0

        for (i, ans) in answers.enumerated() {
            if let ans = ans, !ans.isEmpty {
                if ans == questions[i].answer {
                    correct += 1
                } else {
                    wrong += 1
                    WrongQuestionManager.shared.addWrongQuestion(id: questions[i].id, selectedAnswer: ans)
                }
            } else {
                undone += 1
            }
        }

        correctCount = correct
        wrongCount = wrong
        undoneCount = undone

        QuizHistoryManager.shared.add(
            QuizHistoryRecord(
                id: UUID(),
                date: Date(),
                title: title,
                total: questions.count,
                correct: correct,
                undone: undone,
                wrong: wrong,
                userAnswers: answers,
                questions: questions,
                mode: mode
            )
        )
    }
}
