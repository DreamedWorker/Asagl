//
//  StartGameButton.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import SwiftUI

struct StartGameButton: View {
    let gameType: GameType
    @StateObject private var viewModel = StartGameViewModel()
    @State private var mate: AlertMate = .init()
    
    var body: some View {
        HStack {
            if viewModel.actionType != .DOWNLOADING {
                Text(viewModel.startButtonText)
                    .font(.title3).bold()
                    .foregroundStyle(.white)
                    .padding(.leading, 32).padding(.trailing, 16)
                    .padding(.vertical, 16)
                Image(systemName: "gearshape")
                    .imageScale(.medium)
                    .foregroundStyle(.white)
                    .padding(.trailing, 16)
                    .onTapGesture {
                        WindowManager.shared.openNewGameSettingsWindow(gameType: gameType)
                    }
            } else {
                ProgressView(value: viewModel.progress, total: 1.0)
                    .progressViewStyle(.circular)
                    .padding(.leading, 16)
                    .controlSize(.regular)
                VStack(alignment: .leading) {
                    Text("game.indicator.downloading")
                        .font(.title3).bold()
                        .foregroundStyle(.white)
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    Text("\(viewModel.currentChunk)/\(viewModel.totalChunks)").foregroundStyle(.white)
                        .font(.footnote)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                }.padding(.leading, 8).padding(.trailing, 16)
            }
        }
        .background(Color.accent)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .onAppear {
            viewModel.checkSettings(type: gameType)
        }
        .onChange(of: gameType, {_, newType in
            viewModel.startButtonText = NSLocalizedString("game.indicator.setup", comment: "")
            viewModel.checkSettings(type: newType)
        })
        .onTapGesture {
            switch viewModel.actionType {
            case .NEED_SETUP:
                chooseDir(type: gameType)
            case .FINE:
                startGame()
            case .DOWNLOADING:
                if viewModel.dlIsPaused {
                    viewModel.downloader!.resume()
                    viewModel.dlIsPaused = false
                } else {
                    viewModel.downloader!.pause()
                    viewModel.dlIsPaused = true
                    mate.showAlert(msg: NSLocalizedString("game.waiting.downloadPaused", comment: ""))
                }
            }
        }
        .alert(mate.title, isPresented: $mate.showIt, actions: {}, message: { Text(mate.msg) })
    }
    
    private func chooseDir(type: GameType) {
        let key = (type == .GenshinCN) ? AppConfigKey.GENSHIN_EXEC_PATH : AppConfigKey.ZENLESS_EXEC_PATH
        let panel = NSOpenPanel()
        panel.message = NSLocalizedString("game.panel.choose", comment: "")
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        if panel.runModal() == .OK {
            if let selected = panel.url {
                let files = try! FileManager.default.contentsOfDirectory(atPath: selected.toPath())
                let exeName = (type == .GenshinCN) ? "YuanShen.exe" : "ZenlessZoneZero.exe"
                if files.contains(exeName) && files.contains("config.ini") {
                    AppSettings.setPrefValue(key: key, val: selected.appending(components: exeName).toPath())
                    Task {
                        await MainActor.run {
                            viewModel.checkSettings(type: gameType)
                        }
                    }
                } else {
                    Task {
                        await MainActor.run {
                            viewModel.actionType = .DOWNLOADING
                        }
                        do {
                            try await viewModel.downloadBasicGameData(type: gameType, gameDir: selected) { msg in
                                DispatchQueue.main.async {
                                    self.mate.showAlert(msg: msg, type: .Error)
                                }
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.mate.showAlert(msg: "无法下载基础资源：\(error.localizedDescription)", type: .Error)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func startGame() {
        viewModel.startButtonText = NSLocalizedString("news.waiting", comment: "")
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.viewModel.startButtonText = NSLocalizedString("game.start", comment: "")
            }
        }
        Task.detached {
            do {
                let gameExec = (gameType == .GenshinCN) ?
                AppSettings.getPrefValue(key: AppConfigKey.GENSHIN_EXEC_PATH, defVal: "") :
                AppSettings.getPrefValue(key: AppConfigKey.ZENLESS_EXEC_PATH, defVal: "")
                if AppSettings.getPrefValue(key: AppConfigKey.USING_AB, defVal: false) {
                    GameSettings.tryFixFatalErrorWhileLaunchingGame(gameType: gameType)
                }
                try WineRunner.gameStarter(
                    gameType: gameType,
                    gameExeFile: gameExec,
                    needMSync: AppSettings.getPrefValue(key: AppConfigKey.USING_MSYNC, defVal: true),
                    needHUD: AppSettings.getPrefValue(key: AppConfigKey.USING_HUD, defVal: false)
                )
            } catch {
                await MainActor.run {
                    viewModel.startButtonText = NSLocalizedString("game.start", comment: "")
                    mate.showAlert(msg: "无法打开游戏，\(error.localizedDescription)", type: .Error)
                }
            }
        }
    }
}

fileprivate class StartGameViewModel: ObservableObject, @unchecked Sendable {
    @Published var totalChunks: Int = 1 // 总数量
    @Published var currentChunk: Int = 0 // 当前数量 累加 取两者之商作为下载进度 不显示单个文件进度 不显示下载速度
    @Published var progress: Double = 0.0
    @Published var actionType: ActionType = .NEED_SETUP
    @Published var startButtonText: String = NSLocalizedString("game.indicator.setup", comment: "")
    var downloader: SequentialFileDownloader? = nil
    @Published var dlIsPaused: Bool = false
    
    func checkSettings(type: GameType) {
        let gameExec = (type == .GenshinCN) ?
        AppSettings.getPrefValue(key: AppConfigKey.GENSHIN_EXEC_PATH, defVal: "") :
        AppSettings.getPrefValue(key: AppConfigKey.ZENLESS_EXEC_PATH, defVal: "")
        if gameExec != "" {
            startButtonText = NSLocalizedString("game.start", comment: "")
            actionType = .FINE
        } else {
            startButtonText = NSLocalizedString("game.indicator.setup", comment: "")
            actionType = .NEED_SETUP
        }
    }
    
    func downloadBasicGameData(type: GameType, gameDir: URL, sendErr: @escaping @Sendable (String) -> Void) async throws {
        let manifests = try await GameInstaller.downloadManifestJsonFile(gameType: type)
        let gameResources = manifests.data.manifests.sorted(by: { Int($0.categoryID)! < Int($1.categoryID)! }).first!
        let url = URL(string: gameResources.manifestDownload.urlPrefix + "/" + gameResources.manifest.id)!
        let chunks = try await GameInstaller.downloadChunkManifestFile(
            manifestUrl: url, gameVersion: manifests.data.tag, gameType: type, manifestName: gameResources.categoryID
        )
        downloader = SequentialFileDownloader(
            downloadPrefix: gameResources.chunkDownload.urlPrefix + "/", resource: LocalPaths.resourceDir
        )
        await MainActor.run {
            totalChunks = chunks.chuncks.count
        }
        downloader!.downloadAllFiles(
            chunks.chuncks, selectedPath: gameDir,
            progress: { _, _, cur, tot in
                DispatchQueue.main.async {
                    self.currentChunk = cur
                    self.progress = Double(Double(cur) / Double(tot))
                }
            },
            completion: { isSuccessed, errMsg in
                if isSuccessed {
                    GameInstaller.writeIniFile(gameType: type, selectedPath: gameDir, version: manifests.data.tag)
                    let key = (type == .GenshinCN) ? AppConfigKey.GENSHIN_EXEC_PATH : AppConfigKey.ZENLESS_EXEC_PATH
                    let exeName = (type == .GenshinCN) ? "YuanShen.exe" : "ZenlessZoneZero.exe"
                    AppSettings.setPrefValue(key: key, val: LocalPaths.path(front: gameDir.toPath(), relative: exeName).toPath())
                    DispatchQueue.main.async {
                        self.checkSettings(type: type)
                    }
                } else {
                    sendErr(errMsg?.localizedDescription ?? "unknown error")
                }
            }
        )
    }
    
    enum ActionType {
        case NEED_SETUP
        case FINE
        case DOWNLOADING
    }
}
