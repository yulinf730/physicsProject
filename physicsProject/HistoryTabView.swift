//
//  HistoryList.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/7/22.
//


import SwiftUI

struct HistoryTabView: View {
    @ObservedObject var history = QuizHistoryManager.shared
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("Finished Papers")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)

                    Spacer()

                    if !history.records.isEmpty {
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation { isEditing.toggle() }
                        }
                        .font(.title3)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .padding(.horizontal, 4)

                if history.records.isEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 52))
                            .foregroundColor(.blue.opacity(0.65))

                        Text("No finished papers yet")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Your completed papers will appear here.")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .fill(Color(.systemBackground).opacity(0.9))
                            .shadow(color: Color.blue.opacity(0.06), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 8)
                    .padding(.top, 80)
                } else {
                    ForEach(Array(history.records.reversed().enumerated()), id: \.element.id) { index, record in
                        HistoryTabCard(
                            record: record,
                            onDelete: {
                                deleteRecord(at: record.id)
                            },
                            isEditing: isEditing
                        )
                    }
                }
            }
            .padding([.horizontal, .bottom])
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.07), Color.purple.opacity(0.04)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("")
    }

    func deleteRecord(at id: UUID) {
        if let idx = history.records.firstIndex(where: { $0.id == id }) {
            history.records.remove(at: idx)
            history.save()
        }
    }
}

struct HistoryTabCard: View {
    let record: QuizHistoryRecord
    var onDelete: (() -> Void)? = nil
    var isEditing: Bool = false

    var percentage: Int {
        guard record.total > 0 else { return 0 }
        return Int((Double(record.correct) / Double(record.total) * 100).rounded())
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: HistoryDetailView(record: record)) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: record.mode == .practice ? "bolt.fill" : "doc.plaintext")
                        .font(.system(size: 28))
                        .foregroundColor(record.mode == .practice ? .blue : .purple)
                        .padding(14)
                        .background(
                            Circle().fill((record.mode == .practice ? Color.blue : Color.purple).opacity(0.15))
                        )

                    VStack(alignment: .leading, spacing: 7) {
                        Text(record.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Text("Correct \(record.correct)/\(record.total)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(percentage)%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(record.date.formatted(.dateTime.year().month().day()))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 16) {
                            Label("\(record.correct)", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.green)

                            Label("\(record.wrong)", systemImage: "xmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.red)

                            TagView(
                                text: record.mode == .practice ? "Practice" : "Exam",
                                color: record.mode == .practice ? .blue : .purple
                            )
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue.opacity(0.6))
                        .font(.system(size: 20))
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground).opacity(0.93))
                        .shadow(color: Color.blue.opacity(0.07), radius: 9, x: 0, y: 3)
                )
                .padding(.horizontal, 2)
            }

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

struct TagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 3)
            .padding(.horizontal, 10)
            .background(color)
            .cornerRadius(9)
    }
}
