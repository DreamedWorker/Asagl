//
//  GalleryView.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/10.
//

import SwiftUI

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()

    @State private var isRefreshing = false
    
    let gameType: GameType
    let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            HStack {
                Spacer()
                ZStack {
                    if isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.title.bold())
                            .colorScheme(.dark)
                    }
                }
                .onTapGesture {
                    Task {
                        isRefreshing = true
                        await viewModel.getPhotoAsync(gameType: gameType)
                        isRefreshing = false
                    }
                }
                .help("def.refresh")
            }.padding(.bottom)
            if !viewModel.images.isEmpty {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.images, id: \.self) { img in
                        if let nsImage = viewModel.image(for: img.url) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 280, height: 160)
                                .clipped()
                                .cornerRadius(12)
                                .onTapGesture {
                                    NSWorkspace.shared.open(img.url)
                                }
                        }
                    }
                }
            } else {
                ContentUnavailableView("gallery.empty", systemImage: "tray")
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .onAppear {
            Task { await viewModel.getPhotoAsync(gameType: gameType) }
        }
    }
}

fileprivate class GalleryViewModel: ObservableObject {
    @Published var images: [GalleryImage] = []
    
    private let cache = NSCache<NSURL, NSImage>()

    init() {
        cache.countLimit = 100
    }

    func image(for url: URL) -> NSImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        guard let image = NSImage(contentsOf: url) else { return nil }
        let thumbnail = image.resized(to: NSSize(width: 280, height: 160))
        if let thumbnail {
            cache.setObject(thumbnail, forKey: url as NSURL)
        }
        return thumbnail
    }
    
    func getPhotoAsync(gameType: GameType) async {
        let photos = getPhotos(gameType: gameType)
        await MainActor.run {
            withAnimation {
                images = photos
            }
        }
    }
    
    private func getPhotos(gameType: GameType) -> [GalleryImage] {
        let gameExec = (gameType == .GenshinCN) ?
        AppSettings.getPrefValue(key: AppConfigKey.GENSHIN_EXEC_PATH, defVal: "") :
        AppSettings.getPrefValue(key: AppConfigKey.ZENLESS_EXEC_PATH, defVal: "")
        if gameExec != "" {
            let photoPath = URL(filePath: gameExec).deletingLastPathComponent().appending(component: "ScreenShot")
            if FileManager.default.fileExists(atPath: photoPath.toPath()) {
                let supportedExtensions = ["jpg", "jpeg", "png", "heic", "gif", "bmp", "tiff", "webp"]
                guard let enumerator = FileManager.default.enumerator(
                    at: photoPath,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else { return [] }
                var imageURLs: [GalleryImage] = []
                for case let fileURL as URL in enumerator {
                    if supportedExtensions.contains(fileURL.pathExtension.lowercased()),
                       let _ = NSImage(contentsOf: fileURL) {
                        imageURLs.append(GalleryImage(url: fileURL))
                    }
                }
                return imageURLs
            } else {
                return []
            }
        } else {
            return []
        }
    }
}

fileprivate struct GalleryImage: Identifiable, Hashable {
    let id = UUID()
    let url: URL
}

private extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage? {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: targetSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
