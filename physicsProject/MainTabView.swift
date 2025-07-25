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
            NavigationView {
                MainMenuView(questions: questions)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "book.fill")
                Text("Papers")
            }

            NavigationView {
                WrongBookView(allQuestions: questions)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "exclamationmark.bubble.fill")
                Text("Mistakes")
            }

            NavigationView {
                HistoryTabView() // 历史记录视图
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
        }
    }
}

