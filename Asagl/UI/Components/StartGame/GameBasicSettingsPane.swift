//
//  GameBasicSettingsPane.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/14.
//

import SwiftUI

struct GameBasicSettingsPane: View {
    let gameType: GameType
    let refreshGameState: () -> Void
    let reLocationGame: () -> Void
    
    @State private var showDeleteGame: Bool = false
    
    var body: some View {
        let gameExec = (gameType == .GenshinCN) ?
        AppSettings.getPrefValue(key: AppConfigKey.GENSHIN_EXEC_PATH, defVal: "") :
        AppSettings.getPrefValue(key: AppConfigKey.ZENLESS_EXEC_PATH, defVal: "")
        let exeName = (gameType == .GenshinCN) ? "YuanShen.exe" : "ZenlessZoneZero.exe"
        if gameExec != "" {
            VStack {
                VStack {
                    GameIcon(gameType: gameType, onClick: {})
                    let gameName = NSLocalizedString("gametype.\(gameType.rawValue)", comment: "")
                    Text(gameName).font(.title2).bold()
                }
                .padding(.bottom)
                Form {
                    Section {
                        HStack {
                            Text("game.settings.location")
                            Spacer()
                            Text(gameExec).font(.footnote).foregroundStyle(.secondary).monospaced()
                        }
                        HStack {
                            Spacer()
                            Button("game.settings.openIn", action: { GameSettings.openGameDirInFinder(gameExecPath: gameExec) })
                        }
                    }
                    Section {
                        HStack {
                            Spacer()
                            Button("game.settings.rechoose", action: reLocationGame)
                        }
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("game.settings.rechoose.tip", comment: ""), exeName)
                        ).foregroundStyle(.secondary).font(.callout)
                    }
                    Section {
                        HStack {
                            Spacer()
                            Button(
                                action: {
                                    showDeleteGame = true
                                },
                                label: {
                                    Label("game.settings.uninstall", systemImage: "trash")
                                        .foregroundStyle(.red)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                }
                            )
                        }
                    }
                }.formStyle(.grouped)
            }
            .padding()
            .alert(
                "game.settings.delete.tip", isPresented: $showDeleteGame,
                actions: {
                    Button("def.cancel", role: .cancel, action: { showDeleteGame = false })
                    Button("def.confirm", role: .destructive, action: {
                        GameSettings.unloadGameAndClearRecord(gameType: gameType, gameExecPath: gameExec) {
                            let key = (gameType == .GenshinCN) ? AppConfigKey.GENSHIN_EXEC_PATH : AppConfigKey.ZENLESS_EXEC_PATH
                            AppSettings.setPrefValue(key: key, val: "")
                            DispatchQueue.main.async {
                                self.showDeleteGame = false
                                refreshGameState()
                            }
                        }
                    })
                },
                message: { Text("game.settings.delete.exp") }
            )
        } else {
            ContentUnavailableView("game.settings.blocked", systemImage: "hand.raised")
        }
    }
}

