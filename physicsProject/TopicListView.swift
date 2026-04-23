import SwiftUI

private struct TopicSection: Identifiable {
    let title: String
    let topics: [String]

    var id: String { title }
}

private enum TopicCatalog {
    static let sectionOrder = [
        "Physical quantities and units",
        "Kinematics and acceleration",
        "Forces and momentum",
        "Matter and materials",
        "Work, energy and power",
        "Electricity and circuits",
        "Waves",
        "Atomic and particle physics",
    ]

    static let subtopicOrder = [
        "Units, measurements and vectors",
        "Motion in one and two dimensions",
        "Dynamics and forces",
        "Forces, moments and equilibrium",
        "Momentum and collisions",
        "Density, pressure and upthrust",
        "Deformation of solids",
        "Energy and work",
        "Power and efficiency",
        "Electrical quantities",
        "Resistance and circuit laws",
        "Practical circuits and sensors",
        "General wave properties",
        "Electromagnetic waves",
        "Superposition and stationary waves",
        "Radioactivity and nuclei",
        "Fundamental particles",
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
        let allTopics = Set(questions.map(\.displayTopic))
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
        case "Physical quantities and units":
            return "ruler"
        case "Kinematics and acceleration":
            return "figure.run"
        case "Forces and momentum":
            return "arrow.right.circle.fill"
        case "Matter and materials":
            return "cube.transparent.fill"
        case "Work, energy and power":
            return "bolt.circle.fill"
        case "Electricity and circuits":
            return "bolt.fill"
        case "Waves":
            return "waveform.path"
        case "Atomic and particle physics":
            return "atom"
        default:
            return "book.closed"
        }
    }

    static func symbolColors(for majorTopic: String) -> [Color] {
        switch majorTopic {
        case "Physical quantities and units":
            return [Color.gray.opacity(0.9), Color.blue.opacity(0.75)]
        case "Kinematics and acceleration":
            return [Color.orange.opacity(0.95), Color.yellow.opacity(0.85)]
        case "Forces and momentum":
            return [Color.teal.opacity(0.95), Color.blue.opacity(0.8)]
        case "Matter and materials":
            return [Color.green.opacity(0.9), Color.mint.opacity(0.8)]
        case "Work, energy and power":
            return [Color.yellow.opacity(0.95), Color.orange.opacity(0.85)]
        case "Electricity and circuits":
            return [Color.blue.opacity(0.95), Color.purple.opacity(0.85)]
        case "Waves":
            return [Color.cyan.opacity(0.9), Color.blue.opacity(0.85)]
        case "Atomic and particle physics":
            return [Color.pink.opacity(0.9), Color.red.opacity(0.8)]
        default:
            return [Color.gray.opacity(0.8), Color.gray.opacity(0.5)]
        }
    }
}

struct TopicListView: View {
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

    private var topicSections: [TopicSection] {
        TopicCatalog.groupedTopics(from: questions)
    }

    private func answeredCount(progressTitle: String, questions: [Question]) -> Int {
        guard let saved = QuizProgressStore.shared.load(title: progressTitle, modeRaw: String(describing: mode)),
              saved.matches(questions) else {
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
                VStack(spacing: 8) {
                    Text("Choose Topic")
                        .font(.system(size: isPad ? 38 : 28, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Practise by topic, then go deeper where needed")
                        .font(isPad ? .title3.weight(.semibold) : .subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(topicSections) { section in
                        let sectionQuestions = questions.filter { TopicCatalog.majorTopic(from: $0.displayTopic) == section.title }
                        let completedSubtopics = section.topics.filter { topic in
                            let topicQuestions = questions.filter { $0.displayTopic == topic }
                            return answeredCount(progressTitle: TopicCatalog.subtopic(from: topic), questions: topicQuestions) >= topicQuestions.count && !topicQuestions.isEmpty
                        }.count

                        if section.topics.count == 1, let topic = section.topics.first {
                            let topicQuestions = questions.filter { $0.displayTopic == topic }
                            let progressKey = "TopicPractice_\(topic)"
                            let answeredQuestionCount = answeredCount(progressTitle: section.title, questions: topicQuestions)
                            NavigationLink {
                                QuizPageView(
                                    questions: topicQuestions,
                                    mode: mode,
                                    title: section.title,
                                    paperName: progressKey,
                                    yearProgress: $yearProgress
                                )
                            } label: {
                                TopicCategoryCard(
                                    title: section.title,
                                    subtitle: TopicCatalog.subtopic(from: topic),
                                    questionCount: topicQuestions.count,
                                    subtopicCount: section.topics.count,
                                    completedSubtopics: answeredQuestionCount >= topicQuestions.count && !topicQuestions.isEmpty ? 1 : 0,
                                    answeredQuestionCount: answeredQuestionCount
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
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
                                    subtitle: nil,
                                    questionCount: sectionQuestions.count,
                                    subtopicCount: section.topics.count,
                                    completedSubtopics: completedSubtopics,
                                    answeredQuestionCount: 0
                                )
                            }
                            .buttonStyle(.plain)
                        }
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

    private func answeredCount(for topic: String, questions: [Question]) -> Int {
        guard let saved = QuizProgressStore.shared.load(title: TopicCatalog.subtopic(from: topic), modeRaw: String(describing: mode)),
              saved.matches(questions) else {
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
                        let topicQuestions = questions.filter { $0.displayTopic == topic }
                        let questionCount = topicQuestions.count
                        let answeredQuestionCount = answeredCount(for: topic, questions: topicQuestions)
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
    let subtitle: String?
    let questionCount: Int
    let subtopicCount: Int
    let completedSubtopics: Int
    let answeredQuestionCount: Int

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var progressText: String {
        if subtopicCount <= 1 {
            if questionCount == 1 {
                return "\(answeredQuestionCount) of 1 question answered"
            }
            return "\(answeredQuestionCount) of \(questionCount) questions answered"
        }
        return "\(completedSubtopics)/\(subtopicCount) subtopics completed"
    }

    private var summaryText: String {
        if subtopicCount <= 1 {
            return subtitle ?? title
        }
        return "\(subtopicCount) subtopics • \(questionCount) questions"
    }

    private var tintColor: Color {
        if subtopicCount <= 1 {
            if questionCount > 0 && answeredQuestionCount >= questionCount {
                return .green
            }
            if answeredQuestionCount > 0 {
                return .blue
            }
            return .gray
        }
        if completedSubtopics == subtopicCount && subtopicCount > 0 {
            return .green
        }
        return .blue
    }

    private var isComplete: Bool {
        if subtopicCount <= 1 {
            return questionCount > 0 && answeredQuestionCount >= questionCount
        }
        return completedSubtopics == subtopicCount && subtopicCount > 0
    }

    private var symbolImageName: String {
        if isComplete {
            return "checkmark.seal.fill"
        }
        return symbolName
    }

    private var symbolForegroundStyle: AnyShapeStyle {
        if isComplete {
            return AnyShapeStyle(Color.green)
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: symbolColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var progressValue: Double {
        if subtopicCount <= 1 {
            return Double(answeredQuestionCount)
        }
        return Double(completedSubtopics)
    }

    private var progressTotal: Double {
        if subtopicCount <= 1 {
            return Double(max(questionCount, 1))
        }
        return Double(max(subtopicCount, 1))
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

                Image(systemName: symbolImageName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(symbolForegroundStyle)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(isPad ? .title3.weight(.semibold) : .headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Text(summaryText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                ProgressView(value: progressValue, total: progressTotal)
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
        }
        return "\(answeredCount) of \(questionCount) questions answered"
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
        if questionCount == 0 || answeredCount == 0 {
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
