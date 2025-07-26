import SwiftUI

struct QuizView: View {
    let questions: [Question]
    let title: String

    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var wrongCount = 0
    @State private var unansweredCount = 0   // ✅ 新增未作答计数
    let mode: QuizMode

    init(filteredBy filter: QuizFilter, mode: QuizMode) {
        self.mode = mode
        let allQuestions = QuestionLoader.loadQuestions()
        switch filter {
        case .topic(let topic):
            self.questions = allQuestions.filter { $0.topic == topic }
            self.title = topic
        case .year(let year):
            self.questions = allQuestions.filter { $0.year == year }
            self.title = year
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 8)

            // ✅ Progress indicator
            if currentIndex < questions.count {
                Text("Question \(currentIndex + 1) of \(questions.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Divider()

            // ✅ Quiz Content
            if currentIndex < questions.count {
                QuestionView(
                    question: questions[currentIndex],
                    mode: mode,
                    onAnswered: { selected in
                        if selected.isEmpty {
                            unansweredCount += 1
                        } else {
                            let correct = selected == questions[currentIndex].answer
                            if correct {
                                correctCount += 1
                            } else {
                                wrongCount += 1
                            }
                        }
                        currentIndex += 1
                    }
                )
                .transition(.slide)
            } else {
                // ✅ Summary screen
                VStack(spacing: 20) {
                    Text("🎉 Quiz Complete!")
                        .font(.title)
                        .padding(.top)

                    Text("✅ Correct: \(correctCount)")
                    Text("❌ Wrong: \(wrongCount)")
                    Text("⏸ Undone。: \(unansweredCount)")  // ✅ 新增展示
                    Text("🔢 Total: \(questions.count)")

                    Button("🔁 Restart") {
                        currentIndex = 0
                        correctCount = 0
                        wrongCount = 0
                        unansweredCount = 0
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }

            Spacer()
        }
        .padding()
        .animation(.easeInOut, value: currentIndex)
    }
}
