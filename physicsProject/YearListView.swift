import SwiftUI

struct YearListView: View {
    let questions: [Question]
    let mode: QuizMode
    @Binding var yearProgress: [String: Int]

    @State private var completedYear: String? = nil

    var years: [String] {
        Array(Set(questions.map { $0.year })).sorted(by: >)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Choose Your Paper")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.top, 10)

                ForEach(years, id: \.self) { year in
                    NavigationLink(
                        destination: QuizPageView(
                            questions: questions.filter { $0.year == year },
                            mode: mode,
                            title: year,
                            onQuizCompleted: {
                                completedYear = year
                            }
                        )
                    ) {
                        YearCard(
                            year: year,
                            finished: yearProgress[year] ?? 0
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding([.horizontal, .bottom])
        }
        .onChange(of: completedYear) { year in
            if let y = year {
                yearProgress[y, default: 0] += 1
                completedYear = nil
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.07), Color.purple.opacity(0.04)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

struct YearCard: View {
    let year: String
    let finished: Int

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text(year)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                ProgressView(value: Double(finished), total: 10)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 130)

                if finished > 0 {
                    Text("Finished \(finished) time\(finished > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Not finished yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 22))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.blue.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 2)
    }
}
