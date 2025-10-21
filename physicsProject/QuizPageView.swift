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
    @State private var showAnswerSheet = false
    @State private var showCalculator = false

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
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Text(title)
                        .font(.title2.bold())
                        .padding(.top, 8)

                    Text("Question \(currentIndex + 1)/\(questions.count)")
                        .font(.headline)

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

                    Spacer()

                    // Bottom buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            if currentIndex > 0 {
                                currentIndex -= 1
                            }
                        }) {
                            Text("上一题")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                        .disabled(currentIndex == 0)

                        Button(action: {
                            showAnswerSheet = true
                        }) {
                            Label("答题卡", systemImage: "square.grid.3x3.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            if currentIndex < questions.count - 1 {
                                currentIndex += 1
                            }
                        }) {
                            Text("下一题")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                        .disabled(currentIndex == questions.count - 1)
                    }
                    .padding(.horizontal)

                    if currentIndex == questions.count - 1 {
                        Button(action: {
                            submitQuiz()
                            showResult = true
                        }) {
                            Text("提交")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding([.horizontal, .bottom])
                    }
                }

                Button(action: {
                    showCalculator = true
                }) {
                    Image("calculatorIcon") // 👈 使用你的图片名
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 1)
                }
                .padding()


                if showCalculator {
                    CalculatorOverlayView(isPresented: $showCalculator)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
            .sheet(isPresented: $showAnswerSheet) {
                NavigationView {
                    AnswerSheetView(
                        total: questions.count,
                        answers: answers,
                        onSelect: { index in
                            currentIndex = index
                            showAnswerSheet = false
                        },
                        currentIndex: currentIndex,
                        correctAnswers: questions.map { $0.answer }
                    )
                    .navigationTitle("答题卡")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

