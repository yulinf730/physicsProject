import Foundation

@MainActor
final class ContentStore: ObservableObject {
    @Published var manifest: Manifest?
    @Published var isLoading = false
    @Published var loadError: String?

    private let service = ContentService.shared
    private let versionKey = "manifestVersion"

    var questions: [Question] { manifest?.questions ?? [] }

    func startupLoad() async {
        isLoading = true
        loadError = nil

        // 第一次优先用缓存，保证首屏快 & 离线可用
        if manifest == nil, let cached = service.loadCachedManifestIfAny() {
            self.manifest = cached
        }

        do {
            let m = try await service.fetchManifest()
            self.manifest = m
            let oldVersion = UserDefaults.standard.integer(forKey: versionKey)
            if m.version != oldVersion {
                // 这里可做：清理失效图片、弹“内容已更新”等
                UserDefaults.standard.set(m.version, forKey: versionKey)
            }
        } catch {
            if manifest == nil {
                loadError = "内容加载失败，请检查网络后重试。"
            }
        }
        isLoading = false
    }

    func manualRefresh() async {
        await startupLoad()
    }
}
