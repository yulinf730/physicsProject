import SwiftUI

struct AppUpdatePromptView: View {
    let prompt: AppUpdatePrompt
    let onUpdate: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: prompt.isRequired ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(prompt.isRequired ? .red : .blue)

            VStack(spacing: 10) {
                Text(prompt.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(prompt.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: onUpdate) {
                    Text("Update Now")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(prompt.isRequired ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                if !prompt.isRequired {
                    Button(action: onLater) {
                        Text("Later")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.14))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .padding(24)
    }
}
