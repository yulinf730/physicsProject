import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: ContentStore

    var body: some View {
        VStack {
            if store.isLoading && store.manifest == nil {
                ProgressView("正在加载题库…")
            } else if let err = store.loadError, store.manifest == nil {
                VStack(spacing: 12) {
                    Text(err)
                    Button("重试") { Task { await store.manualRefresh() } }
                }
            } else {
                // 显示题目列表（示例）
                List(store.questions) { q in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(q.text).font(.headline)
                        RemoteImageView(url: q.imageURL)
                    }
                }
                .refreshable {
                    await store.manualRefresh()
                }
            }
        }
    }
}
