import SwiftUI

struct MainMenuView: View {
    let questions: [Question]

    @State private var selectedMode: QuizMode? = nil
    @State private var pendingRoute: PendingRoute? = nil
    @State private var showModeSheet = false // 用 sheet 替换原 actionSheet/confirmationDialog
    @State private var path: [MenuDestination] = []

    @ObservedObject private var yearProgressManager = YearProgressManager.shared

    enum PendingRoute {
        case year
        case topic
    }

    enum MenuDestination: Hashable {
        case year(QuizMode)
        case topic(QuizMode)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {

                    Spacer(minLength: 30)

                    // 欢迎语
                    VStack(alignment: .center, spacing: 10) {
                        Text("Physics Practice")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Choose how you want to practice")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 12)

                    // 卡片按钮
                    VStack(spacing: 28) {
                        MenuCard(
                            icon: "book.closed",
                            title: "Practice by Topic",
                            color: .purple
                        ) {
                            pendingRoute = .topic
                            showModeSheet = true
                        }

                        MenuCard(
                            icon: "calendar",
                            title: "Practice by Year",
                            color: .blue
                        ) {
                            pendingRoute = .year
                            showModeSheet = true
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
            }
            .navigationTitle("")
            .toolbar(path.isEmpty ? .hidden : .visible, for: .navigationBar)
            .navigationDestination(for: MenuDestination.self) { destination in
                switch destination {
                case .year(let mode):
                    YearGroupListView(
                        questions: questions,
                        mode: mode,
                        yearProgress: $yearProgressManager.progress
                    )
                case .topic(let mode):
                    TopicListView(
                        questions: questions,
                        mode: mode,
                        yearProgress: $yearProgressManager.progress
                    )
                }
            }
        }
        // --- 用 sheet 选择模式，居中且不会跑屏 ---
        .sheet(isPresented: $showModeSheet) {
            VStack(spacing: 28) {
                Text("Choose your mode")
                    .font(.title2)
                    .bold()
                    .padding(.top, 28)
                Button {
                    selectedMode = .practice
                    showModeSheet = false
                    handleNavigation()
                } label: {
                    Text("Practice Mode")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(14)
                }
                Button {
                    selectedMode = .exam
                    showModeSheet = false
                    handleNavigation()
                } label: {
                    Text("Exam Mode")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(14)
                }
                Button("Cancel", role: .cancel) {
                    showModeSheet = false
                    pendingRoute = nil
                }
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 28)
            .presentationDetents([.height(270)]) // sheet高度自适应
        }
    }

    private func handleNavigation() {
        guard let selectedMode, let pendingRoute else { return }

        switch pendingRoute {
        case .year:
            path.append(.year(selectedMode))
        case .topic:
            path.append(.topic(selectedMode))
        }

        self.pendingRoute = nil
    }
}

// MARK: - 卡片样式的按钮
struct MenuCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(color.gradient)
                    .clipShape(Circle())
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 22)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: color.opacity(0.07), radius: 10, x: 0, y: 5)
            .animation(.easeInOut, value: UUID())
        }
    }
}
