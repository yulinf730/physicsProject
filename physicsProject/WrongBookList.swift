import SwiftUI

struct WrongBookList: View {
    let allQuestions: [Question]

    var body: some View {
        List(allQuestions, id: \.id) { question in
            VStack(alignment: .leading) {
                Text("Topic: \(question.topic)  Year: \(question.year)")
                Text("Correct Answer: \(question.answer)").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
