//
//  StartGameViewModel.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation
import GameKit

class StartGameViewModel: ObservableObject, @unchecked Sendable {
    @Published var totalChunks: Int = 1 // 总数量
    @Published var currentChunk: Int = 0 // 当前数量 累加 取两者之商作为下载进度 不显示单个文件进度 不显示下载速度
    @Published var progress: Double = 0.0
    @Published var actionType: ActionType = .NEED_SETUP
    @Published var startButtonText: String = NSLocalizedString("game.indicator.setup", comment: "")
    
    func checkSettings(type: GameKit.GameType) {
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
    
    func startDownloadGame(selectedPath: String, gameType: GameKit.GameType, sendError: @escaping @Sendable (String) -> Void) async throws {
        try await GameKit.downloadGame(
            gameType: gameType, selectedPath: URL(fileURLWithPath: selectedPath), resourcePath: Paths.resourceDir,
            setTotalCounts: { total in
                Task {
                    await self.setTotalCounts(num: total)
                }
            },
            reportProgress: { cur, tot, prog in
                DispatchQueue.main.async {
                    self.currentChunk = cur
                    self.totalChunks = tot
                    self.progress = prog
                }
            },
            postDownload: {
                let key = (gameType == .GenshinCN) ? AppConfigKey.GENSHIN_EXEC_PATH : AppConfigKey.ZENLESS_EXEC_PATH
                let exeName = (gameType == .GenshinCN) ? "YuanShen.exe" : "ZenlessZoneZero.exe"
                AppSettings.setPrefValue(key: key, val: Paths.path(front: selectedPath, relative: exeName).toPath())
                DispatchQueue.main.async {
                    self.checkSettings(type: gameType)
                }
            },
            sendErrorMessage: { msg in
                sendError(msg)
            }
        )
    }
    
    private func setTotalCounts(num: Int) async {
        await MainActor.run {
            self.totalChunks = num
        }
    }
}

extension StartGameViewModel {
    enum ActionType {
        case NEED_SETUP
        case FINE
        case DOWNLOADING
    }
}
