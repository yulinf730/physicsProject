import SwiftUI

struct ContentView: View {
    let questions: [Question] = QuestionLoader.loadQuestions()
    @StateObject private var updateManager = AppUpdateManager.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        MainTabView(questions: questions)
            .task {
                await updateManager.checkForUpdates()
            }
            .sheet(item: $updateManager.prompt) { prompt in
                AppUpdatePromptView(
                    prompt: prompt,
                    onUpdate: {
                        openURL(prompt.updateURL)
                    },
                    onLater: {
                        updateManager.dismissOptionalPrompt()
                    }
                )
                .presentationDetents([.height(prompt.isRequired ? 360 : 400)])
                .interactiveDismissDisabled(prompt.isRequired)
            }
    }
}

#Preview {
    ContentView()
}
