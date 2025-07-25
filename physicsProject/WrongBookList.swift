import SwiftUI

struct WrongBookList: View {
    let allQuestions: [Question]

    var body: some View {
        List(allQuestions, id: \.id) { question in
            VStack(alignment: .leading) {
                Text("题目: \(question.topic)  年份: \(question.year)")
                Text("正确答案: \(question.answer)").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
