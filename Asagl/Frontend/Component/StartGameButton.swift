//
//  StartGameButton.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import SwiftUI
import GameKit

struct StartGameButton: View {
    @State private var isHoveringStartButton = false
    @StateObject private var viewModel = StartGameViewModel()
    @StateObject private var svm = SharedViewModel.shared
    @State private var showSettingsPane: Bool = false
    
    let gameType: GameKit.GameType
    
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
                        showSettingsPane = true
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
        .onAppear {
            viewModel.checkSettings(type: gameType)
        }
        .onChange(of: gameType, {_, newType in
            viewModel.startButtonText = NSLocalizedString("game.indicator.setup", comment: "")
            viewModel.checkSettings(type: newType)
        })
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.accent)
                .shadow(color: isHoveringStartButton ? .white.opacity(0.6) : .clear, radius: 8, x: 0, y: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHoveringStartButton = hovering
            }
        }
        .onTapGesture {
            switch viewModel.actionType {
            case .NEED_SETUP:
                Task {
                    await chooseDir(type: gameType)
                }
            case .FINE:
                startGame()
            case .DOWNLOADING:
                svm.sendGlobalMessage(context: NSLocalizedString("game.waiting.download", comment: ""), msgType: .Info)
            }
        }
        .sheet(isPresented: $showSettingsPane, content: {
            NavigationStack {
                TabView {
                    GameBasicSettingsPane(
                        gameType: gameType,
                        refreshGameState: {
                            showSettingsPane = false
                            viewModel.checkSettings(type: gameType)
                        },
                        reLocationGame: {
                            showSettingsPane = false
                            Task { await chooseDir(type: gameType) }
                        }
                    ).tabItem({ Text("game.settings.tab.baisc") })
                    GameUpdatePanel(gameType: gameType).tabItem({ Text("game.settings.tab.update") })
                    GameAdvancedSettingsPane().tabItem({ Text("game.settings.tab.advanced") })
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("def.close", action: { showSettingsPane = false })
                })
            }
        })
    }
}

extension StartGameButton {
    private func chooseDir(type: GameKit.GameType) async {
        let key = (type == .GenshinCN) ? AppConfigKey.GENSHIN_EXEC_PATH : AppConfigKey.ZENLESS_EXEC_PATH
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        await panel.begin()
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
                        try await viewModel.startDownloadGame(selectedPath: selected.toPath(), gameType: gameType) { msg in
                            DispatchQueue.main.async {
                                svm.sendGlobalMessage(context: msg, msgType: .Error)
                            }
                        }
                    } catch {
                        await MainActor.run {
                            svm.sendGlobalMessage(context: "无法下载游戏，\(error.localizedDescription)", msgType: .Error)
                        }
                    }
                }
            }
        }
    }
}

extension StartGameButton {
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
                    GameKit.tryFixFatalErrorWhileLaunchingGame(gameType: gameType)
                }
                _ = try WineRunner.runWineCmd(
                    args: [gameExec],
                    needMSync: AppSettings.getPrefValue(key: AppConfigKey.USING_MSYNC, defVal: true),
                    needHUD: AppSettings.getPrefValue(key: AppConfigKey.USING_HUD, defVal: false),
                    isGameRun: true
                )
            } catch {
                await MainActor.run {
                    viewModel.startButtonText = NSLocalizedString("game.start", comment: "")
                    svm.sendGlobalMessage(
                        context: "无法打开游戏，\(error.localizedDescription)",
                        msgType: .Error
                    )
                }
            }
        }
    }
}
