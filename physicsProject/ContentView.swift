import SwiftUI

struct ContentView: View {
    let questions: [Question] = QuestionLoader.loadQuestions()

    var body: some View {
        MainTabView(questions: questions)
    }
}

#Preview {
    ContentView()
}
