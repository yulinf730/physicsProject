import SwiftUI
import Foundation

private struct QuizHeaderView: View {
    let title: String
    let currentIndex: Int
    let totalQuestions: Int

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .padding(.top, 8)

            Text("Question \(min(currentIndex + 1, max(totalQuestions, 1)))/\(totalQuestions)")
                .font(.headline)
        }
    }
}

private struct QuizBottomControls: View {
    let currentIndex: Int
    let totalQuestions: Int
    let onPrevious: () -> Void
    let onShowAnswerSheet: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrevious) {
                Text("上一题")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .disabled(currentIndex == 0)

            Button(action: onShowAnswerSheet) {
                Label("答题卡", systemImage: "square.grid.3x3.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: onNext) {
                Text("下一题")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .disabled(currentIndex == totalQuestions - 1)
        }
        .padding(.horizontal)
    }
}

private struct SubmitQuizButton: View {
    let onSubmit: () -> Void

    var body: some View {
        Button(action: onSubmit) {
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

private struct FloatingCalculatorButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
    }
}

struct QuizPageView: View {
    @Environment(\.dismiss) private var dismiss

    let questions: [Question]
    let mode: QuizMode
    let title: String
    let paperName: String
    @Binding var yearProgress: [String: Int]

    var onQuizCompleted: (() -> Void)? = nil

    @State private var currentIndex = 0
    @State private var answers: [String?]
    @State private var showResult = false
    @State private var correctCount = 0
    @State private var wrongCount = 0
    @State private var undoneCount = 0
    @State private var didCompleted = false
    @State private var showAnswerSheet = false
    @State private var showCalculator = false

    // 关键：先记录要跳转的题号，等 sheet 消失后再跳
    @State private var pendingJumpIndex: Int? = nil

    private var answerSheetDisplayMode: AnswerSheetDisplayMode {
        mode == .exam
            ? .progressOnly
            : .scored(correctAnswers: questions.map(\.answer))
    }

    init(
        questions: [Question],
        mode: QuizMode,
        title: String,
        paperName: String,
        yearProgress: Binding<[String: Int]>,
        onQuizCompleted: (() -> Void)? = nil
    ) {
        self.questions = questions
        self.mode = mode
        self.title = title
        self.paperName = paperName
        self._yearProgress = yearProgress
        self.onQuizCompleted = onQuizCompleted

        let blankProgress = QuizProgress.blank(
            title: title,
            mode: mode,
            questionCount: questions.count,
            questionIDs: questions.map(\.id)
        )

        if let saved = QuizProgressStore.shared.load(title: title, modeRaw: blankProgress.modeRaw),
           saved.matches(questions) {
            _answers = State(initialValue: saved.answers)
            _currentIndex = State(initialValue: saved.clampedCurrentIndex)
            print("✅ restored progress in init for \(title)")
        } else {
            _answers = State(initialValue: blankProgress.answers)
            _currentIndex = State(initialValue: blankProgress.currentIndex)
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
                        answers = QuizProgress.blank(
                            title: title,
                            mode: mode,
                            questionCount: questions.count,
                            questionIDs: questions.map(\.id)
                        ).answers
                        correctCount = 0
                        wrongCount = 0
                        undoneCount = 0
                        currentIndex = 0
                        showResult = false
                        didCompleted = false
                        pendingJumpIndex = nil

                        QuizProgressStore.shared.clear(title: title, modeRaw: String(describing: mode))
                        yearProgress[paperName] = 0
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
                        QuizHeaderView(
                            title: title,
                            currentIndex: currentIndex,
                            totalQuestions: questions.count
                        )

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
                                        persistQuizState(currentIndex: currentIndex, answers: newAnswers)
                                    }
                                )
                                .tag(i)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .animation(.spring(), value: currentIndex)
                        .onChange(of: currentIndex) { _ in
                            syncVisibleProgress()
                        }

                        Spacer()

                        QuizBottomControls(
                            currentIndex: currentIndex,
                            totalQuestions: questions.count,
                            onPrevious: {
                                if currentIndex > 0 {
                                    moveToQuestion(currentIndex - 1)
                                }
                            },
                            onShowAnswerSheet: {
                                showAnswerSheet = true
                            },
                            onNext: {
                                if currentIndex < questions.count - 1 {
                                    moveToQuestion(currentIndex + 1)
                                }
                            }
                        )

                        if currentIndex == questions.count - 1 {
                            SubmitQuizButton {
                                submitQuiz()
                                showResult = true
                            }
                        }
                    }

                    FloatingCalculatorButton {
                        showCalculator = true
                    }

                    if showCalculator {
                        CalculatorOverlayView(isPresented: $showCalculator)
                            .transition(.move(edge: .bottom))
                            .zIndex(1)
                    }
                }
                .sheet(isPresented: $showAnswerSheet, onDismiss: {
                    if let target = pendingJumpIndex,
                       questions.indices.contains(target) {
                        moveToQuestion(target)
                        print("✅ jumped to question index =", target)
                        pendingJumpIndex = nil
                    }
                }) {
                    NavigationView {
                        AnswerSheetView(
                            total: questions.count,
                            answers: answers,
                            onSelect: { index in
                                // 不要在这里直接 currentIndex = index
                                // 先记下来，等 sheet 关闭后再跳
                                pendingJumpIndex = index
                                showAnswerSheet = false
                            },
                            currentIndex: currentIndex,
                            displayMode: answerSheetDisplayMode
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
            syncVisibleProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveQuizProgress)) { _ in
            saveProgress()
            syncVisibleProgress()
        }
        .onDisappear {
            if !showResult {
                saveProgress()
                syncVisibleProgress()
            }
        }
    }

    func restoreProgressIfNeeded() {
        let modeRaw = String(describing: mode)

        guard let saved = QuizProgressStore.shared.load(title: title, modeRaw: modeRaw) else {
            print("ℹ️ no saved progress onAppear for \(title)")
            return
        }

        guard saved.matches(questions) else {
            print("ℹ️ saved progress exists but does not match current question set for \(title)")
            return
        }

        currentIndex = saved.clampedCurrentIndex
        answers = saved.answers

        print("✅ restored progress onAppear for \(title)")
        print("   restored currentIndex =", currentIndex)
        print("   restored answers =", answers)
        syncVisibleProgress()
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
        let summary = QuizScoreSummary(questions: questions, answers: answers)
        for (i, ans) in answers.enumerated() {
            if let ans = ans, !ans.isEmpty {
                if ans != questions[i].answer {
                    WrongQuestionManager.shared.addWrongQuestion(id: questions[i].id, selectedAnswer: ans)
                }
            }
        }

        correctCount = summary.correct
        wrongCount = summary.wrong
        undoneCount = summary.undone

        QuizHistoryManager.shared.add(summary.makeHistoryRecord(title: title, questions: questions, answers: answers, mode: mode))

        QuizProgressStore.shared.clear(title: title, modeRaw: String(describing: mode))
        yearProgress[paperName] = questions.count
    }

    private func moveToQuestion(_ index: Int) {
        currentIndex = index
        persistQuizState(currentIndex: index, answers: answers)
    }

    private func persistQuizState(currentIndex: Int, answers: [String?]) {
        saveProgress(currentIndex: currentIndex, answers: answers)
        yearProgress[paperName] = QuizProgressCalculator.completedQuestionCount(
            questionCount: questions.count,
            currentIndex: currentIndex,
            answers: answers
        )
    }

    private func syncVisibleProgress() {
        yearProgress[paperName] = QuizProgressCalculator.completedQuestionCount(
            questionCount: questions.count,
            currentIndex: currentIndex,
            answers: answers
        )
    }
}
