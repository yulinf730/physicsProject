import SwiftUI

struct AnswerSheetView: View {
    let total: Int
    let answers: [String?]
    let onSelect: (Int) -> Void
    var currentIndex: Int = -1
    let correctAnswers: [String]

    var body: some View {
        VStack(alignment: .leading) {
            Text("答题卡")
                .font(.title2.bold())
                .padding(.top)
                .padding(.horizontal)

            // 色块说明
            HStack(spacing: 16) {
                Label("未作答", systemImage: "circle.fill")
                    .foregroundColor(.gray)
                Label("答对", systemImage: "circle.fill")
                    .foregroundColor(.green)
                Label("答错", systemImage: "circle.fill")
                    .foregroundColor(.red)
                Label("当前题", systemImage: "circle")
                    .foregroundColor(.blue)
            }
            .font(.caption)
            .padding(.horizontal)

            Divider().padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                    ForEach(0..<total, id: \.self) { index in
                        let userAnswer = answers[index]
                        let correctAnswer = correctAnswers[index]
                        let isCurrent = index == currentIndex

                        Button(action: {
                            onSelect(index)
                        }) {
                            Text("\(index + 1)")
                                .frame(width: 44, height: 44)
                                .background(backgroundColor(userAnswer, correctAnswer))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(
                                        isCurrent ? Color.blue : Color.clear,
                                        lineWidth: 3
                                    )
                                )
                        }
                    }
                }
                .padding()
            }

            Spacer()
        }
    }

    func backgroundColor(_ user: String?, _ correct: String) -> Color {
        if let u = user {
            return u == correct ? .green : .red
        } else {
            return .gray.opacity(0.4)
        }
    }
}
