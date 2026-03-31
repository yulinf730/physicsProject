import SwiftUI

struct YearListView: View {
    let questions: [Question]
    let mode: QuizMode
    @Binding var yearProgress: [String: Int]

    @State private var completedYear: String? = nil

    private var years: [String] {
        Array(Set(questions.map(\.year))).sorted(by: >)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Choose Your Paper")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.top, 10)

                ForEach(years, id: \.self) { year in
                    let yearQuestions = questions.filter { $0.year == year }
                    let questionCount = yearQuestions.count
                    let savedProgress = yearProgress[year] ?? 0
                    let validProgress = min(max(savedProgress, 0), questionCount)

                    NavigationLink {
                        QuizPageView(
                            questions: yearQuestions,
                            mode: mode,
                            title: year,
                            paperName: year,
                            yearProgress: $yearProgress,
                            onQuizCompleted: {
                                completedYear = year
                                yearProgress[year] = questionCount
                            }
                        )
                    } label: {
                        YearCard(
                            title: year,
                            progress: validProgress,
                            questionCount: questionCount
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.10),
                    Color.purple.opacity(0.06)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private struct YearCard: View {
    let title: String
    let progress: Int
    let questionCount: Int

    private var statusText: String {
        if questionCount == 0 {
            return "No questions"
        } else if progress == 0 {
            return "Not started"
        } else if progress >= questionCount {
            return "Completed"
        } else {
            return "Continue from Q\(progress + 1)"
        }
    }

    private var statusColor: Color {
        if questionCount == 0 {
            return .gray
        } else if progress == 0 {
            return .gray
        } else if progress >= questionCount {
            return .green
        } else {
            return .blue
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.18), Color.purple.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: progress >= questionCount && questionCount > 0 ? "checkmark.seal.fill" : "doc.text")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(progress >= questionCount && questionCount > 0 ? .green : .blue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Text(statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(statusColor)

                ProgressView(value: Double(progress), total: Double(max(questionCount, 1)))
                    .progressViewStyle(.linear)
                    .tint(progress >= questionCount && questionCount > 0 ? .green : .blue)

                Text("\(progress)/\(questionCount) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.8))
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
