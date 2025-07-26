import SwiftUI

struct MainMenuView: View {
    let questions: [Question]

    @State private var selectedMode: QuizMode? = nil
    @State private var pendingRoute: Route? = nil
    @State private var showModeSheet = false // 用 sheet 替换原 actionSheet/confirmationDialog

    @State private var navigateToYear = false
    @State private var navigateToTopic = false

    @StateObject var yearProgressManager = YearProgressManager()
    @State private var yearProgress: [String: Int] = [:]

    enum Route {
        case year
        case topic
    }

    var body: some View {
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
                        icon: "calendar",
                        title: "Practice by Year",
                        color: .blue
                    ) {
                        pendingRoute = .year
                        showModeSheet = true
                    }

                    MenuCard(
                        icon: "book.closed",
                        title: "Practice by Topic",
                        color: .purple
                    ) {
                        pendingRoute = .topic
                        showModeSheet = true
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // 年份进度展示
                if !yearProgress.isEmpty {
                    VStack(alignment: .trailing, spacing: 6) {
                        ForEach(Array(yearProgress.keys.sorted()), id: \.self) { year in
                            HStack {
                                Text("\(year):")
                                    .foregroundColor(.primary)
                                ProgressView(value: Double(yearProgress[year] ?? 0), total: 10)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .frame(width: 120)
                                Text("\(yearProgress[year] ?? 0)x")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                    .padding(.trailing, 24)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity)
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
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
                    handleNavigate()
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
                    handleNavigate()
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
        // 跳转链接
        .background(
            NavigationLink(
                destination: selectedMode == nil ? nil : AnyView(
                    YearListView(
                        questions: questions,
                        mode: selectedMode ?? .practice,
                        yearProgress: $yearProgressManager.progress
                    )
                ),
                isActive: $navigateToYear,
                label: { EmptyView() }
            )
            .hidden()
        )
        .background(
            NavigationLink(
                destination:
                    selectedMode == nil
                    ? AnyView(EmptyView())
                    : AnyView(TopicListView(questions: questions, mode: selectedMode!)),
                isActive: $navigateToTopic,
                label: { EmptyView() }
            )
                .hidden()
        )
        .onAppear {
            yearProgress = yearProgressManager.progress
        }
    }

    private func handleNavigate() {
        guard let route = pendingRoute, let _ = selectedMode else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if route == .year {
                navigateToYear = true
            } else if route == .topic {
                navigateToTopic = true
            }
            pendingRoute = nil
        }
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
