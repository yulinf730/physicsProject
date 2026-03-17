import SwiftUI

private enum WrongGroupBy: String, CaseIterable, Identifiable {
    case topic = "Topic"
    case year  = "Year"
    var id: String { rawValue }
}

struct WrongBookView: View {
    let allQuestions: [Question]

    @State private var wrongQuestions: [Question] = []
    @State private var selectedQuestion: Question? = nil

    @State private var isEditing = false
    @State private var searchText = ""
    @State private var groupBy: WrongGroupBy = .topic

    // Practice launcher
    @State private var startPractice = false
    @State private var practiceSet: [Question] = []

    // Topic picker
    @State private var showTopicPicker = false
    @State private var selectedTopics = Set<String>()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Mistakes")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.green)
                Spacer()
                if !wrongQuestionsFiltered.isEmpty {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { isEditing.toggle() }
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }
                    .font(.title3)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)

            // Search & Group controls
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search by id/topic/year…", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .cornerRadius(12)

                Menu {
                    Picker("Group by", selection: $groupBy) {
                        ForEach(WrongGroupBy.allCases) { by in
                            Text(by.rawValue).tag(by)
                        }
                    }
                } label: {
                    Label(groupBy.rawValue, systemImage: "square.grid.2x2")
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if wrongQuestions.isEmpty {
                EmptyMistakesView().padding(.top, 40)
            } else if wrongQuestionsFiltered.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No results").font(.headline)
                    Text("Try a different search or grouping.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
            } else {
                List {
                    ForEach(groupedKeys, id: \.self) { key in
                        Section(header: sectionHeader(key: key, count: groupedDict[key]?.count ?? 0)) {
                            ForEach(groupedDict[key] ?? [], id: \.id) { question in
                                WrongBookCard(
                                    question: question,
                                    onDelete: { deleteQuestion(id: question.id) },
                                    isEditing: isEditing
                                ) {
                                    if !isEditing { selectedQuestion = question }
                                }
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteQuestion(id: question.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }

            // Bottom bar: single button
            if !wrongQuestionsFiltered.isEmpty {
                HStack(spacing: 12) {
                    Button {
                        // Preselect ALL topics so tapping "Start" = practice all
                        selectedTopics = Set(availableTopics.map(\.name))
                        showTopicPicker = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Label("Practice by Topics", systemImage: "list.bullet.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(.thinMaterial)
              
            }
        }  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.06), Color.blue.opacity(0.04)]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear(perform: loadWrongQuestions)
        .sheet(item: $selectedQuestion) { q in
            QuestionView(
                question: q,
                mode: .practice,
                selectedAnswer: nil,
                onAnswered: { selected in
                    if selected == q.answer {
                        WrongQuestionManager.shared.removeWrongQuestion(id: q.id)
                        loadWrongQuestions()
                    } else {
                        WrongQuestionManager.shared.addWrongQuestion(id: q.id, selectedAnswer: selected)
                        loadWrongQuestions()
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTopicPicker) {
            TopicPickerSheet(
                topics: availableTopics,
                preselected: selectedTopics,
                onCancel: { showTopicPicker = false },
                onConfirm: { chosen in
                    selectedTopics = chosen
                    buildPracticeSetForSelectedTopics()
                    showTopicPicker = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        // Navigate to a practice session using QuizPageView
        .background(
            NavigationLink(
                destination: QuizPageView(
                    questions: practiceSet,
                    mode: .practice,
                    title: practiceTitle,
                    onQuizCompleted: { loadWrongQuestions() }
                ),
                isActive: $startPractice,
                label: { EmptyView() }
            )
            .hidden()
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Derived data

    var wrongIDs: [String] {
        WrongQuestionManager.shared.allWrongQuestionIDs()
    }

    var wrongQuestionsFiltered: [Question] {
        let base = wrongQuestions
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.id.lowercased().contains(q)
            || $0.topic.lowercased().contains(q)
            || $0.year.lowercased().contains(q)
        }
    }

    private var groupedDict: [String: [Question]] {
        switch groupBy {
        case .topic:
            return Dictionary(grouping: wrongQuestionsFiltered, by: { $0.topic })
                .mapValues { $0.sorted { $0.id < $1.id } }
        case .year:
            return Dictionary(grouping: wrongQuestionsFiltered, by: { $0.year })
                .mapValues { $0.sorted { $0.id < $1.id } }
        }
    }

    private var groupedKeys: [String] {
        let keys = Array(groupedDict.keys)
        switch groupBy {
        case .topic: return keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        case .year:  return keys.sorted(by: >)
        }
    }

    private var practiceTitle: String {
        switch groupBy {
        case .topic: return "Practice: Mistakes (by Topic)"
        case .year:  return "Practice: Mistakes (by Year)"
        }
    }

    private var availableTopics: [(name: String, count: Int)] {
        let counts = Dictionary(grouping: wrongQuestionsFiltered, by: { $0.topic })
            .mapValues { $0.count }
        return counts.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            .map { ($0, counts[$0] ?? 0) }
    }

    // MARK: - Actions

    func loadWrongQuestions() {
        let ids = WrongQuestionManager.shared.allWrongQuestionIDs()
        wrongQuestions = allQuestions.filter { ids.contains($0.id) }
    }

    func deleteQuestion(id: String) {
        WrongQuestionManager.shared.removeWrongQuestion(id: id)
        loadWrongQuestions()
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    private func buildPracticeSetForSelectedTopics() {
        let chosen = selectedTopics
        practiceSet = wrongQuestionsFiltered.filter { chosen.contains($0.topic) }
        startPractice = !practiceSet.isEmpty
        #if os(iOS)
        if startPractice {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif
    }

    // MARK: - UI helpers

    @ViewBuilder
    private func sectionHeader(key: String, count: Int) -> some View {
        HStack {
            Text(key).font(.headline)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .padding(.vertical, 2)
                .padding(.horizontal, 8)
                .background(Color.secondary.opacity(0.15))
                .clipShape(Capsule())
        }
        .textCase(nil)
    }
}

// MARK: - Card

struct WrongBookCard: View {
    let question: Question
    var onDelete: (() -> Void)? = nil
    var isEditing: Bool = false
    var onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 14) {
                    if !question.imageName.isEmpty {
                        Image(question.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .cornerRadius(12)
                            .shadow(radius: 3, x: 1, y: 2)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(question.id)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text("Topic: \(question.topic)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if let userWrong = WrongQuestionManager.shared.wrongAnswer(for: question.id), !userWrong.isEmpty {
                            Text("Your Wrong Answer: \(userWrong)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground).opacity(0.88))
                        .shadow(color: .blue.opacity(0.07), radius: 8, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEditing ? Color.pink.opacity(0.7) : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())

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

// MARK: - Topic Picker Sheet

struct TopicPickerSheet: View {
    let topics: [(name: String, count: Int)]
    let preselected: Set<String>
    var onCancel: () -> Void
    var onConfirm: (Set<String>) -> Void

    @State private var chosen: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if topics.isEmpty {
                        Text("No topics available in the current filter.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(topics, id: \.name) { t in
                            Toggle(isOn: Binding(
                                get: { chosen.contains(t.name) },
                                set: { newValue in
                                    if newValue { chosen.insert(t.name) } else { chosen.remove(t.name) }
                                }
                            )) {
                                HStack {
                                    Text(t.name)
                                    Spacer()
                                    Text("\(t.count)")
                                        .font(.caption2)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 6)
                                        .background(Color.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Topics")
                }
            }
            .navigationTitle("Practice by Topics")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") { onConfirm(chosen) }
                        .disabled(chosen.isEmpty)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Select All") { chosen = Set(topics.map(\.name)) }
                    Spacer()
                    Button("Clear") { chosen.removeAll() }
                }
            }
            .onAppear { chosen = preselected }
        }
    }
}

// Empty state
struct EmptyMistakesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 48))
                .foregroundColor(.green.opacity(0.7))
            Text("No mistakes yet")
                .font(.headline)
                .foregroundColor(.primary)
            Text("Your wrong questions will appear here.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.green.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 24)
    }
}
