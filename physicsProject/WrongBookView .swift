import SwiftUI

struct WrongBookView: View {
    let allQuestions: [Question]
    @State private var wrongQuestions: [Question] = []
    @State private var selectedQuestion: Question? = nil

    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("Mistakes")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.green)
                    Spacer()
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation { isEditing.toggle() }
                    }
                    .font(.title3)
                    .padding(.trailing, 6)
                    .disabled(wrongQuestions.isEmpty)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .padding(.horizontal, 4)

                ForEach(wrongQuestions, id: \.id) { question in
                    WrongBookCard(
                        question: question,
                        onDelete: {
                            deleteQuestion(id: question.id)
                        },
                        isEditing: isEditing
                    ) {
                        if !isEditing {
                            selectedQuestion = question
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.06), Color.blue.opacity(0.04)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear(perform: loadWrongQuestions)
        .sheet(item: $selectedQuestion) { q in
            QuestionView(
                question: q,
                mode: .practice,
                onAnswered: { selected in
                    if selected == q.answer {
                        WrongQuestionManager.shared.removeWrongQuestion(id: q.id)
                        loadWrongQuestions()
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    func loadWrongQuestions() {
        let ids = WrongQuestionManager.shared.allWrongQuestionIDs()
        wrongQuestions = allQuestions.filter { ids.contains($0.id) }
    }

    func deleteQuestion(id: String) {
        WrongQuestionManager.shared.removeWrongQuestion(id: id)
        loadWrongQuestions()
    }
}

// MARK: - 单个错题卡片，带垃圾桶
struct WrongBookCard: View {
    let question: Question
    var onDelete: (() -> Void)? = nil
    var isEditing: Bool = false
    var onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 14) {
                    if !question.imageName.isEmpty {
                        Image(question.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .cornerRadius(12)
                            .shadow(radius: 3, x: 1, y: 2)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(question.id)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text("Topic: \(question.topic)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if let userWrong = WrongQuestionManager.shared.wrongAnswer(for: question.id), !userWrong.isEmpty {
                            Text("Your Wrong Answer: \(userWrong)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground).opacity(0.88))
                        .shadow(color: .blue.opacity(0.07), radius: 8, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEditing ? Color.pink.opacity(0.7) : Color.clear, lineWidth: 2)
                )
                .padding(.horizontal, 2)
            }
            .buttonStyle(PlainButtonStyle())
            // 右上角垃圾桶
            if isEditing {
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.red)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                }
                .offset(x: 10, y: -10)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}
