import SwiftUI
import Foundation

@main
struct physicsProjectApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var supportStore = SupportStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supportStore)
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
