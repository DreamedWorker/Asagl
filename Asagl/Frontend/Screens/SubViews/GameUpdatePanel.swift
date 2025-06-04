//
//  GameUpdatePanel.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/6/4.
//

import SwiftUI
import GameKit

struct GameUpdatePanel: View {
    let gameType: GameKit.GameType
    @State private var mate: AlertMate = .init()
    @State var totalChunks: Int = 1 // 总数量
    @State var currentChunk: Int = 0 // 当前数量 累加 取两者之商作为下载进度 不显示单个文件进度 不显示下载速度
    @State var progress: Double = 0.0
    @State var showDownloadPart: Bool = false
    
    var body: some View {
        VStack {
            let gameExec = (gameType == .GenshinCN) ?
            AppSettings.getPrefValue(key: AppConfigKey.GENSHIN_EXEC_PATH, defVal: "") :
            AppSettings.getPrefValue(key: AppConfigKey.ZENLESS_EXEC_PATH, defVal: "")
            HStack {
                Spacer()
                Button("game.upd.mainCheck", action: {
                    Task {
                        do {
                            try await GameKit.GameUpdate.checkHasUpdate(
                                gameType: gameType,
                                gameDir: URL(filePath: gameExec).deletingLastPathComponent(),
                                resourceDir: Paths.resourceDir,
                                setTotalCounts: { cur in
                                    DispatchQueue.main.async {
                                        self.showDownloadPart = true
                                        self.totalChunks = cur
                                    }
                                },
                                reportProgress: { cur, tot, pro in
                                    DispatchQueue.main.async {
                                        self.currentChunk = cur
                                        self.totalChunks = tot
                                        self.progress = pro
                                    }
                                },
                                postDownload: {
                                    DispatchQueue.main.async {
                                        self.mate.showAlert(msg: "版本更新完成")
                                        self.showDownloadPart = false
                                        self.currentChunk = 0
                                        self.progress = 0.0
                                        self.totalChunks = 1
                                    }
                                },
                                sendErrorMessage: { errMsg in
                                    DispatchQueue.main.async {
                                        self.showDownloadPart = false
                                        self.currentChunk = 0
                                        self.progress = 0.0
                                        self.totalChunks = 1
                                        self.mate.showAlert(msg: errMsg, type: .Error)
                                    }
                                }
                            )
                        } catch {
                            DispatchQueue.main.async {
                                self.mate.showAlert(msg: error.localizedDescription)
                            }
                        }
                    }
                })
            }.padding(.bottom)
            if showDownloadPart {
                VStack {
                    ProgressView(value: progress, total: 1.0).progressViewStyle(.linear)
                    HStack {
                        Text("\(currentChunk)/\(totalChunks)").font(.callout).foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            Spacer()
            HStack {
                Text("game.upd.reminder").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
        .alert(mate.title, isPresented: $mate.showIt, actions: {}, message: { Text(mate.msg) })
    }
}
