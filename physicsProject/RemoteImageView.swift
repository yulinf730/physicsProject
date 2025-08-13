import SwiftUI

struct RemoteImageView: View {
    let url: URL?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task {
            guard image == nil, let url else { return }
            image = try? await ImageCache.shared.image(for: url)
        }
    }
}
