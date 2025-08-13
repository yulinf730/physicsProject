import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private init() {}

    func image(for url: URL) async throws -> UIImage {
        let fileURL = cachedFileURL(for: url)
        if let data = try? Data(contentsOf: fileURL),
           let img = UIImage(data: data) {
            return img
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        try? data.write(to: fileURL, options: .atomic)
        guard let img = UIImage(data: data) else {
            throw URLError(.cannotDecodeRawData)
        }
        return img
    }

    private func cachedFileURL(for url: URL) -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        // 用 URL 编码后的字符串当文件名，简单可靠
        let name = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
            ?? UUID().uuidString
        return caches.appendingPathComponent(name)
    }
}
