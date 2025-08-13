//
//  ContentSourceError.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/8/13.
//


import Foundation

enum ContentSourceError: Error {
    case noCache, decodeFailed(Error)
}

final class ContentService {
    static let shared = ContentService()
    private init() {}

    // TODO: 换成你的 COS/CDN 上的 manifest.json 地址
    private let manifestURL = URL(string: "https://YOUR-CDN-DOMAIN/manifest.json")!

    private let etagKey = "manifestETag"
    private let cachedManifestName = "manifest.json"

    private var localManifestURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(cachedManifestName)
    }

    func fetchManifest() async throws -> Manifest {
        var req = URLRequest(url: manifestURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        if let etag = UserDefaults.standard.string(forKey: etagKey) {
            req.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse,
               let newETag = http.value(forHTTPHeaderField: "ETag"),
               newETag.isEmpty == false {
                UserDefaults.standard.set(newETag, forKey: etagKey)
            }
            try data.write(to: localManifestURL, options: .atomic)
            return try decodeManifest(from: data)
        } catch {
            // 网络失败或 304 无内容时，使用本地缓存
            let data = try Data(contentsOf: localManifestURL)
            return try decodeManifest(from: data)
        }
    }

    func loadCachedManifestIfAny() -> Manifest? {
        if let data = try? Data(contentsOf: localManifestURL) {
            return try? decodeManifest(from: data)
        }
        return nil
    }

    private func decodeManifest(from data: Data) throws -> Manifest {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        do { return try dec.decode(Manifest.self, from: data) }
        catch { throw ContentSourceError.decodeFailed(error) }
    }
}
