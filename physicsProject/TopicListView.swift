import SwiftUI

struct TopicListView: View {
    let questions: [Question]
    let mode: QuizMode

    // 章节列表自动提取、去重、排序
    var topics: [String] {
        Array(Set(questions.map { $0.topic })).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Choose Topic")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.purple)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ForEach(topics, id: \.self) { topic in
                    NavigationLink(
                        destination: QuizPageView(
                            questions: questions.filter { $0.topic == topic },
                            mode: mode,
                            title: topic
                        )
                    ) {
                        TopicCard(topic: topic)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding([.horizontal, .bottom])
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.07), Color.blue.opacity(0.04)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("")
    }
}

// MARK: - 卡片样式的章节选择
struct TopicCard: View {
    let topic: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .padding(14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            Text(topic)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.vertical, 8)

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 20))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.purple.opacity(0.05), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 2)
    }
}
