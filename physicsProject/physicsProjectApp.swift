import SwiftUI
import Foundation

@main
struct physicsProjectApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                NotificationCenter.default.post(name: .saveQuizProgress, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let saveQuizProgress = Notification.Name("saveQuizProgress")
}
