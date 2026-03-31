//
//  MainTabView.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/7/22.
//

import SwiftUI

struct MainTabView: View {
    let questions: [Question]
    @StateObject var historyManager = QuizHistoryManager.shared // 历史记录全局

    var body: some View {
        TabView {
            MainMenuView(questions: questions)
            .tabItem {
                Image(systemName: "book.fill")
                Text("Papers")
            }

            NavigationStack {
                WrongBookView(allQuestions: questions)
            }
            .tabItem {
                Image(systemName: "exclamationmark.bubble.fill")
                Text("Mistakes")
            }

            NavigationStack {
                HistoryTabView() // 历史记录视图
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SupportView()
            }
            .tabItem {
                Label("Support", systemImage: "heart.fill")
            }
        }
    }
}
