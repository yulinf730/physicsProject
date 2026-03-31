import SwiftUI

struct QuestionView: View {
    let question: Question
    let mode: QuizMode
    let selectedAnswer: String?
    var onAnswered: (String) -> Void

    @State private var isZoomed = false
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var localSelectedAnswer: String? = nil
    @GestureState private var isDragging = false

    private var isAnswered: Bool {
        effectiveSelectedAnswer != nil
    }

    private var effectiveSelectedAnswer: String? {
        selectedAnswer ?? localSelectedAnswer
    }

    @ViewBuilder
    var questionImageView: some View {
        if let uiImage = UIImage(named: question.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .cornerRadius(12)
                .padding()
                .onTapGesture {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        isZoomed = true
                        imageScale = 1.0
                        lastScale = 1.0
                        imageOffset = .zero
                    }
                }
                .opacity(isZoomed ? 0.5 : 1.0)
                .allowsHitTesting(!isZoomed)
        } else {
            ZStack {
                Color(.systemGray5)
                Text("⚠️ 图片不存在: \(question.imageName)")
                    .foregroundColor(.red)
                    .padding()
            }
            .frame(height: 180)
            .cornerRadius(12)
            .padding()
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        questionImageView

                        HStack(spacing: 32) {
                            ForEach(question.options, id: \.self) { option in
                                Button(action: {
                                    guard effectiveSelectedAnswer == nil else { return }

                                    if mode == .practice {
                                        triggerHaptic(success: option == question.answer)
                                        if option != question.answer {
                                            WrongQuestionManager.shared.addWrongQuestion(
                                                id: question.id,
                                                selectedAnswer: option
                                            )
                                        }
                                    }

                                    localSelectedAnswer = option
                                    onAnswered(option)
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 60, height: 60)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                        Text(option)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                borderColor(for: option),
                                                lineWidth: effectiveSelectedAnswer == option ? 3 : 0
                                            )
                                    )
                                }
                                .disabled(effectiveSelectedAnswer != nil)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 30)

                        if mode == .practice, isAnswered {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Answer: \(question.answer)")
                                    .font(.headline)
                                    .foregroundColor(.blue)

                                Text(question.explanation)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 60)
                    }
                }

                if isZoomed {
                    ZStack {
                        Color.black.opacity(0.9)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    isZoomed = false
                                    imageScale = 1.0
                                    lastScale = 1.0
                                    imageOffset = .zero
                                }
                            }
                            .contentShape(Rectangle())

                        if let uiImage = UIImage(named: question.imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .scaleEffect(imageScale)
                                .offset(imageOffset)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                let delta = value / lastScale
                                                imageScale *= delta
                                                imageScale = max(1.0, min(imageScale, 4.0))
                                                lastScale = value
                                            }
                                            .onEnded { _ in
                                                lastScale = 1.0
                                                if imageScale <= 1.03 {
                                                    withAnimation(.spring()) {
                                                        imageScale = 1.0
                                                        imageOffset = .zero
                                                    }
                                                }
                                            },
                                        DragGesture()
                                            .updating($isDragging) { _, state, _ in
                                                state = true
                                            }
                                            .onChanged { value in
                                                if imageScale <= 1.01 {
                                                    imageOffset = CGSize(width: 0, height: value.translation.height)
                                                } else {
                                                    imageOffset = value.translation
                                                }
                                            }
                                            .onEnded { value in
                                                if imageScale <= 1.01 && abs(value.translation.height) > 100 {
                                                    withAnimation(.spring()) {
                                                        isZoomed = false
                                                        imageScale = 1.0
                                                        lastScale = 1.0
                                                        imageOffset = .zero
                                                    }
                                                } else {
                                                    withAnimation(.spring()) {
                                                        if imageScale <= 1.01 {
                                                            imageOffset = .zero
                                                        } else {
                                                            imageOffset.width += value.translation.width
                                                            imageOffset.height += value.translation.height
                                                        }
                                                    }
                                                }
                                            }
                                    )
                                )
                                .animation(.interactiveSpring(), value: imageOffset)
                                .animation(.interactiveSpring(), value: imageScale)
                                .zIndex(2)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
        }
    }

    private func borderColor(for option: String) -> Color {
        guard effectiveSelectedAnswer == option else { return .clear }

        if mode == .practice {
            return option == question.answer ? .green : .red
        } else {
            return .orange
        }
    }

    func triggerHaptic(success: Bool) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .error)
    }
}
