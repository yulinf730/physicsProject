import SwiftUI
import Foundation

struct QuizPageView: View {
    @Environment(\.dismiss) private var dismiss

    let questions: [Question]
    let mode: QuizMode
    let title: String
    var onQuizCompleted: (() -> Void)? = nil

    @State private var currentIndex = 0
    @State private var answers: [String?]
    @State private var showResult = false
    @State private var correctCount = 0
    @State private var wrongCount = 0
    @State private var undoneCount = 0
    @State private var canGoNext = false
    @State private var didCompleted = false
    @State private var showAnswerSheet = false
    @State private var showCalculator = false

    init(questions: [Question], mode: QuizMode, title: String, onQuizCompleted: (() -> Void)? = nil) {
        self.questions = questions
        self.mode = mode
        self.title = title
        self.onQuizCompleted = onQuizCompleted

        let emptyAnswers: [String?] = Array(repeating: nil, count: questions.count)
        let modeRaw = String(describing: mode)

        if let saved = QuizProgressStore.shared.load(title: title, modeRaw: modeRaw),
           saved.answers.count == questions.count,
           saved.questionIDs == questions.map({ $0.id }) {

            _answers = State(initialValue: saved.answers)
            _currentIndex = State(initialValue: min(saved.currentIndex, max(questions.count - 1, 0)))
            print("✅ restored progress in init for \(title)")
        } else {
            _answers = State(initialValue: emptyAnswers)
            _currentIndex = State(initialValue: 0)
            print("ℹ️ no matching saved progress in init for \(title)")
        }
    }

    var body: some View {
        Group {
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
                        QuizProgressStore.shared.clear(title: title, modeRaw: String(describing: mode))
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
                                    selectedAnswer: answers[i],
                                    onAnswered: { selected in
                                        var newAnswers = answers
                                        newAnswers[i] = selected
                                        answers = newAnswers
                                        canGoNext = true
                                        saveProgress(currentIndex: currentIndex, answers: newAnswers)
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

                        HStack(spacing: 12) {
                            Button(action: {
                                if currentIndex > 0 {
                                    let newIndex = currentIndex - 1
                                    currentIndex = newIndex
                                    saveProgress(currentIndex: newIndex, answers: answers)
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
                                    let newIndex = currentIndex + 1
                                    currentIndex = newIndex
                                    saveProgress(currentIndex: newIndex, answers: answers)
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
                        Image("calculatorIcon")
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
                                saveProgress(currentIndex: index, answers: answers)
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
        .onAppear {
            restoreProgressIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveQuizProgress)) { _ in
            saveProgress()
        }
        .onDisappear {
            if !showResult {
                saveProgress()
            }
        }
    }

    func restoreProgressIfNeeded() {
        let modeRaw = String(describing: mode)

        guard let saved = QuizProgressStore.shared.load(title: title, modeRaw: modeRaw) else {
            print("ℹ️ no saved progress onAppear for \(title)")
            return
        }

        guard saved.answers.count == questions.count,
              saved.questionIDs == questions.map({ $0.id }) else {
            print("ℹ️ saved progress exists but does not match current question set for \(title)")
            return
        }

        currentIndex = min(saved.currentIndex, max(questions.count - 1, 0))
        answers = saved.answers

        print("✅ restored progress onAppear for \(title)")
        print("   restored currentIndex =", currentIndex)
        print("   restored answers =", answers)
    }

    func saveProgress(currentIndex: Int? = nil, answers: [String?]? = nil) {
        let progress = QuizProgress(
            title: title,
            modeRaw: String(describing: mode),
            questionIDs: questions.map { $0.id },
            currentIndex: currentIndex ?? self.currentIndex,
            answers: answers ?? self.answers
        )
        QuizProgressStore.shared.save(progress)
        print("💾 saved at \(Date())")
        print("💾 currentIndex =", progress.currentIndex)
        print("💾 answers =", progress.answers)
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

        QuizProgressStore.shared.clear(title: title, modeRaw: String(describing: mode))
    }
}
