import SwiftUI

private struct TopicSection: Identifiable {
    let title: String
    let topics: [String]

    var id: String { title }
    var totalQuestions: Int { topics.count }
}

private enum TopicCatalog {
    static let sectionOrder = [
        "Motion, Forces and Energy",
        "Thermal Physics",
        "Waves",
        "Electricity and Magnetism",
        "Nuclear Physics",
        "Space Physics",
    ]

    static let subtopicOrder = [
        "Measurement and Quantities",
        "Motion and Kinematics",
        "Forces and Movement",
        "Forces and Interactions",
        "Mass, Density and Pressure",
        "Momentum and Turning Effects",
        "Work and Power",
        "Energy Stores and Resources",
        "Thermal Properties",
        "Thermal Transfer",
        "Particle Model and States",
        "General Wave Properties",
        "Sound",
        "Reflection and Images",
        "Refraction and Lenses",
        "Electromagnetic Spectrum",
        "Electrical Quantities",
        "Electric Circuits and Resistance",
        "Static Electricity, Safety and Electronics",
        "Magnetism",
        "Electromagnetism",
        "Electromagnetic Induction",
        "Atomic Structure",
        "Radiation, Safety and Uses",
        "Radioactive Decay and Half-Life",
        "Earth and Solar System",
        "Stars and Fusion",
        "Stars and Cosmology",
    ]

    static func majorTopic(from topic: String) -> String {
        topic.components(separatedBy: " / ").first ?? topic
    }

    static func subtopic(from topic: String) -> String {
        let parts = topic.components(separatedBy: " / ")
        return parts.count > 1 ? parts[1] : topic
    }

    static func sortIndex(for subtopic: String) -> Int {
        subtopicOrder.firstIndex(of: subtopic) ?? Int.max
    }

    static func groupedTopics(from questions: [Question]) -> [TopicSection] {
        let allTopics = Set(questions.map(\.topic))
        let grouped = Dictionary(grouping: allTopics) { majorTopic(from: $0) }

        return sectionOrder.compactMap { section in
            guard let topics = grouped[section], !topics.isEmpty else { return nil }
            return TopicSection(
                title: section,
                topics: topics.sorted { lhs, rhs in
                    sortIndex(for: subtopic(from: lhs)) < sortIndex(for: subtopic(from: rhs))
                }
            )
        }
    }

    static func symbolName(for majorTopic: String) -> String {
        switch majorTopic {
        case "Motion, Forces and Energy":
            return "figure.run"
        case "Thermal Physics":
            return "thermometer.sun"
        case "Waves":
            return "waveform.path"
        case "Electricity and Magnetism":
            return "bolt.fill"
        case "Nuclear Physics":
            return "atom"
        case "Space Physics":
            return "sparkles"
        default:
            return "book.closed"
        }
    }

    static func symbolColors(for majorTopic: String) -> [Color] {
        switch majorTopic {
        case "Motion, Forces and Energy":
            return [Color.orange.opacity(0.95), Color.yellow.opacity(0.85)]
        case "Thermal Physics":
            return [Color.red.opacity(0.9), Color.orange.opacity(0.85)]
        case "Waves":
            return [Color.cyan.opacity(0.9), Color.blue.opacity(0.85)]
        case "Electricity and Magnetism":
            return [Color.blue.opacity(0.95), Color.purple.opacity(0.85)]
        case "Nuclear Physics":
            return [Color.green.opacity(0.9), Color.teal.opacity(0.85)]
        case "Space Physics":
            return [Color.indigo.opacity(0.95), Color.pink.opacity(0.8)]
        default:
            return [Color.gray.opacity(0.8), Color.gray.opacity(0.5)]
        }
    }
}

struct TopicListView: View {
    let questions: [Question]
    let mode: QuizMode
    @Binding var yearProgress: [String: Int]
    @ObservedObject private var yearProgressManager = YearProgressManager.shared

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var columns: [GridItem] {
        isPad
            ? [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)]
            : [GridItem(.flexible())]
    }

    private var topicSections: [TopicSection] {
        TopicCatalog.groupedTopics(from: questions)
    }

    private func answeredCount(for topic: String, questionCount: Int) -> Int {
        guard let saved = QuizProgressStore.shared.load(title: TopicCatalog.subtopic(from: topic), modeRaw: String(describing: mode)),
              saved.answers.count == questionCount else {
            return 0
        }

        return saved.answers.reduce(into: 0) { count, answer in
            if let answer, !answer.isEmpty {
                count += 1
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("Choose Topic")
                    .font(.system(size: isPad ? 38 : 28, weight: .bold))
                    .foregroundColor(.purple)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(topicSections) { section in
                        let sectionQuestions = questions.filter { TopicCatalog.majorTopic(from: $0.topic) == section.title }
                        let completedSubtopics = section.topics.filter { topic in
                            let count = questions.filter { $0.topic == topic }.count
                            return answeredCount(for: topic, questionCount: count) >= count && count > 0
                        }.count

                        NavigationLink {
                            TopicSubtopicListView(
                                title: section.title,
                                topics: section.topics,
                                questions: sectionQuestions,
                                mode: mode,
                                yearProgress: $yearProgress
                            )
                        } label: {
                            TopicCategoryCard(
                                title: section.title,
                                subtopicCount: section.topics.count,
                                questionCount: sectionQuestions.count,
                                completedSubtopics: completedSubtopics
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: isPad ? 960 : .infinity)
                .padding(.horizontal, 16)

                Spacer(minLength: 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.10),
                    Color.blue.opacity(0.06),
                    Color.orange.opacity(0.03)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private struct TopicSubtopicListView: View {
    let title: String
    let topics: [String]
    let questions: [Question]
    let mode: QuizMode
    @Binding var yearProgress: [String: Int]

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var columns: [GridItem] {
        isPad
            ? [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)]
            : [GridItem(.flexible())]
    }

    private func answeredCount(for topic: String, questionCount: Int) -> Int {
        guard let saved = QuizProgressStore.shared.load(title: TopicCatalog.subtopic(from: topic), modeRaw: String(describing: mode)),
              saved.answers.count == questionCount else {
            return 0
        }

        return saved.answers.reduce(into: 0) { count, answer in
            if let answer, !answer.isEmpty {
                count += 1
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: isPad ? 38 : 30, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Choose a subtopic to practise")
                        .font(isPad ? .title3.weight(.semibold) : .subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(topics, id: \.self) { topic in
                        let topicQuestions = questions.filter { $0.topic == topic }
                        let questionCount = topicQuestions.count
                        let answeredQuestionCount = answeredCount(for: topic, questionCount: questionCount)
                        let progressKey = "TopicPractice_\(topic)"

                        NavigationLink {
                            QuizPageView(
                                questions: topicQuestions,
                                mode: mode,
                                title: TopicCatalog.subtopic(from: topic),
                                paperName: progressKey,
                                yearProgress: $yearProgress
                            )
                        } label: {
                            TopicCard(
                                topic: TopicCatalog.subtopic(from: topic),
                                questionCount: questionCount,
                                answeredCount: answeredQuestionCount
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: isPad ? 960 : .infinity)
                .padding(.horizontal, 16)

                Spacer(minLength: 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.10),
                    Color.blue.opacity(0.06),
                    Color.orange.opacity(0.03)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private struct TopicCategoryCard: View {
    let title: String
    let subtopicCount: Int
    let questionCount: Int
    let completedSubtopics: Int

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var progressText: String {
        "\(completedSubtopics)/\(subtopicCount) subtopics completed"
    }

    private var tintColor: Color {
        completedSubtopics == subtopicCount ? .green : .blue
    }

    private var symbolName: String {
        TopicCatalog.symbolName(for: title)
    }

    private var symbolColors: [Color] {
        TopicCatalog.symbolColors(for: title)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: symbolColors.map { $0.opacity(0.22) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)

                Image(systemName: completedSubtopics == subtopicCount ? "checkmark.seal.fill" : symbolName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        completedSubtopics == subtopicCount
                            ? AnyShapeStyle(Color.green)
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: symbolColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(isPad ? .title3.weight(.semibold) : .headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Text("\(subtopicCount) subtopics • \(questionCount) questions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                ProgressView(value: Double(completedSubtopics), total: Double(max(subtopicCount, 1)))
                    .progressViewStyle(.linear)
                    .tint(tintColor)

                Text(progressText)
                    .font(.caption)
                    .foregroundColor(tintColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.8))
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.vertical, isPad ? 22 : 18)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

private struct TopicCard: View {
    let topic: String
    let questionCount: Int
    let answeredCount: Int

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var answeredSummaryText: String {
        if questionCount == 1 {
            return "\(answeredCount) of 1 question answered"
        } else {
            return "\(answeredCount) of \(questionCount) questions answered"
        }
    }

    private var statusText: String {
        if questionCount == 0 {
            return "No questions"
        } else if answeredCount == 0 {
            return "Not started"
        } else if answeredCount >= questionCount {
            return "Completed"
        } else if answeredCount == 1 {
            return "1 question answered"
        } else {
            return "\(answeredCount) questions answered"
        }
    }

    private var statusColor: Color {
        if questionCount == 0 {
            return .gray
        } else if answeredCount == 0 {
            return .gray
        } else if answeredCount >= questionCount {
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
                            colors: [Color.purple.opacity(0.18), Color.blue.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: answeredCount >= questionCount && questionCount > 0 ? "checkmark.seal.fill" : "book.closed")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(answeredCount >= questionCount && questionCount > 0 ? .green : .purple)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(topic)
                    .font(isPad ? .title3.weight(.semibold) : .headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Text(statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(statusColor)

                ProgressView(value: Double(answeredCount), total: Double(max(questionCount, 1)))
                    .progressViewStyle(.linear)
                    .tint(answeredCount >= questionCount && questionCount > 0 ? .green : .blue)

                Text(answeredSummaryText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.8))
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.vertical, isPad ? 20 : 16)
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
