//
//  GameUpdatePane.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/14.
//

import SwiftUI

struct GameUpdatePane: View {
    let gameType: GameType
    @State private var gameVersionNow: String = "0.0.0"
    @State private var gameChunkManifests: [GameManifests.ManifestElement] = []
    @State private var alertMate: AlertMate = .init()
    @State private var newVersion: String = ""
    @StateObject private var dlHost: DownloadHost = .init()
    
    var body: some View {
        let gameExec = (gameType == .GenshinCN) ?
        AppSettings.getPrefValue(key: AppConfigKey.GENSHIN_EXEC_PATH, defVal: "") :
        AppSettings.getPrefValue(key: AppConfigKey.ZENLESS_EXEC_PATH, defVal: "")
        let configPath = URL(filePath: gameExec).deletingLastPathComponent().appending(component: "config.ini")
        let gameConfig = INIFileReader(string: try! String(contentsOf: configPath, encoding: .utf8))
        if gameExec == "" {
            ContentUnavailableView("game.settings.blocked", systemImage: "hand.raised")
        } else {
            NavigationStack {
                HStack {
                    Text("game.upd.currentVersion")
                    Spacer()
                    Text(gameVersionNow).foregroundStyle(.secondary)
                }
                .onAppear {
                    gameVersionNow = gameConfig.value(forKey: "game_version") ?? "0.0.0"
                }
                if newVersion != "" {
                    HStack {
                        Text("game.upd.remoteVersion")
                        Spacer()
                        Text(newVersion).foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Spacer()
                    Button("game.upd.check") {
                        Task {
                            do {
                                let result = try await GameUpdater.downloadNeoManifest(gameType: gameType, originVersion: gameVersionNow)
                                DispatchQueue.main.async {
                                    var tempList = result.data.manifests
                                    tempList = tempList.sorted(by: { $0.categoryID < $1.categoryID })
                                    self.gameChunkManifests = tempList
                                    self.newVersion = result.data.tag
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.alertMate.showAlert(msg: error.localizedDescription)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom)
                if dlHost.showDownloadBar {
                    VStack {
                        ProgressView(value: dlHost.progress, total: 1.0)
                        HStack {
                            Text("\(dlHost.currentChunk)/\(dlHost.totalChunks)").font(.callout).monospaced()
                            Spacer()
                            Text("game.upd.waiting").font(.callout).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom)
                }
                if !gameChunkManifests.isEmpty {
                    ScrollView(showsIndicators: false) {
                        LazyVStack {
                            ForEach(gameChunkManifests, id: \.categoryID) { manifest in
                                FeatureTile(iconName: "list.clipboard", descriptionKey: manifest.categoryName)
                                    .onTapGesture {
                                        Task {
                                            do {
                                                let preparedDownloadResource = try await GameUpdater.doPreparation(
                                                    gameType: gameType, originVersion: gameVersionNow, neoVersion: newVersion, item: manifest
                                                )
                                                let main = manifest.categoryName.contains("游戏资源")
                                                dlHost.doDelete(preparedDownloadResource.toDelete, gameExec: gameExec)
                                                dlHost.doDownload(
                                                    preparedDownloadResource.toDownload, manifest: manifest, gameType: gameType,
                                                    oldVersion: gameVersionNow, gameExec: gameExec,
                                                    isMainResource: main,
                                                    sendInfo: { info in
                                                        alertMate.showAlert(msg: info)
                                                    }
                                                )
                                            } catch {
                                                DispatchQueue.main.async {
                                                    self.alertMate.showAlert(msg: error.localizedDescription, type: .Error)
                                                }
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    .frame(minHeight: 200, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    HStack {
                        Text("game.upd.tip").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .alert(alertMate.title, isPresented: $alertMate.showIt, actions: {}, message: { Text(alertMate.msg) })
        }
    }
}

fileprivate class DownloadHost: ObservableObject, @unchecked Sendable {
    @Published var showDownloadBar = false
    @Published var totalChunks: Int = 1 // 总数量
    @Published var currentChunk: Int = 0 // 当前数量 累加 取两者之商作为下载进度 不显示单个文件进度 不显示下载速度
    @Published var progress: Double = 0.0
    
    func doDelete(_ requiredList: [SophonChunkFile], gameExec: String) {
        let gameRoot = URL(filePath: gameExec).deletingLastPathComponent()
        for file in requiredList {
            let path = gameRoot.appending(component: file.file)
            if FileManager.default.fileExists(atPath: path.toPath()) {
                try? FileManager.default.removeItem(at: path)
            }
        }
    }
    
    func doDownload(_ requiredFiles: [SophonChunkFile],
                    manifest: GameManifests.ManifestElement,
                    gameType: GameType,
                    oldVersion: String,
                    gameExec: String,
                    isMainResource: Bool,
                    sendInfo: @escaping @Sendable @MainActor (String) -> Void,
                    gameVersion: String? = nil
    ) {
        let dlLink = manifest.chunkDownload.urlPrefix + "/"
        let gameRoot = URL(filePath: gameExec).deletingLastPathComponent()
        let downloader = SequentialFileDownloader(downloadPrefix: dlLink, resource: LocalPaths.resourceDir)
        totalChunks = requiredFiles.count
        showDownloadBar = true
        downloader.downloadAllFiles(
            requiredFiles,
            selectedPath: gameRoot,
            progress: { _, _, cur, tot in
                DispatchQueue.main.async {
                    self.currentChunk = cur
                    self.progress = Double(Double(cur) / Double(tot))
                }
            },
            completion: { isSuccessed, errMsg in
                if isSuccessed {
                    if isMainResource {
                        GameInstaller.writeIniFile(gameType: gameType, selectedPath: gameRoot, version: gameVersion!)
                    }
                    GameUpdater.removeOldManifest(gameType: gameType, oldVersion: oldVersion, manifestId: manifest.categoryID)
                    DispatchQueue.main.async {
                        self.showDownloadBar = false
                        self.progress = 0.0
                        self.currentChunk = 0
                        self.totalChunks = 1
                        sendInfo(NSLocalizedString("game.upd.done", comment: ""))
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showDownloadBar = false
                        self.progress = 0.0
                        self.currentChunk = 0
                        self.totalChunks = 1
                        sendInfo(errMsg?.localizedDescription ?? "unknown error")
                    }
                }
            }
        )
    }
}
