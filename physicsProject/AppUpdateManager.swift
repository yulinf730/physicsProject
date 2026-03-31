import Foundation
import SwiftUI

struct AppUpdatePrompt: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let updateURL: URL
    let isRequired: Bool
}

private struct RemoteAppVersionConfig: Decodable {
    let latestVersion: String
    let minimumSupportedVersion: String?
    let updateURL: String
    let title: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case latestVersion = "latest_version"
        case minimumSupportedVersion = "minimum_supported_version"
        case updateURL = "update_url"
        case title
        case message
    }
}

@MainActor
final class AppUpdateManager: ObservableObject {
    static let shared = AppUpdateManager()

    @Published var prompt: AppUpdatePrompt?

    // Replace this with your own hosted JSON file URL.
    private let versionConfigURLString = "https://yulinf730.github.io/physics-version-check/version.json"

    private init() {}

    func checkForUpdates() async {
        guard
            let configURL = URL(string: versionConfigURLString),
            !versionConfigURLString.isEmpty
        else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: configURL)
            let config = try JSONDecoder().decode(RemoteAppVersionConfig.self, from: data)
            guard let updateURL = URL(string: config.updateURL) else { return }

            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            let latestVersion = config.latestVersion
            let minimumVersion = config.minimumSupportedVersion ?? latestVersion

            let needsForcedUpdate = Self.compare(currentVersion, minimumVersion) == .orderedAscending
            let hasNewerVersion = Self.compare(currentVersion, latestVersion) == .orderedAscending

            guard needsForcedUpdate || hasNewerVersion else {
                prompt = nil
                return
            }

            prompt = AppUpdatePrompt(
                title: config.title ?? (needsForcedUpdate ? "Update Required" : "Update Available"),
                message: config.message ?? defaultMessage(
                    currentVersion: currentVersion,
                    latestVersion: latestVersion,
                    required: needsForcedUpdate
                ),
                updateURL: updateURL,
                isRequired: needsForcedUpdate
            )
        } catch {
            print("Failed to check app version:", error.localizedDescription)
        }
    }

    func dismissOptionalPrompt() {
        guard prompt?.isRequired == false else { return }
        prompt = nil
    }

    private func defaultMessage(currentVersion: String, latestVersion: String, required: Bool) -> String {
        if required {
            return "Your current version (\(currentVersion)) is no longer supported. Please update to version \(latestVersion) to continue."
        } else {
            return "Version \(latestVersion) is available. You are currently using version \(currentVersion)."
        }
    }

    private static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let rhsParts = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let maxCount = max(lhsParts.count, rhsParts.count)

        for index in 0..<maxCount {
            let lhsValue = index < lhsParts.count ? lhsParts[index] : 0
            let rhsValue = index < rhsParts.count ? rhsParts[index] : 0

            if lhsValue < rhsValue { return .orderedAscending }
            if lhsValue > rhsValue { return .orderedDescending }
        }

        return .orderedSame
    }
}
