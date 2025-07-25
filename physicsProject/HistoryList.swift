//
//  HistoryList.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/7/22.
//
import SwiftUI

struct HistoryList: View {
    @Binding var selection: QuizHistoryRecord?
    @ObservedObject var history = QuizHistoryManager.shared
    var body: some View {
        List(Array(history.records.reversed()), id: \.id, selection: $selection) { record in
            Text(record.title)
        }
    }
}


