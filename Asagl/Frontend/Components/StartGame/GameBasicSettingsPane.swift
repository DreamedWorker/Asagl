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
            VStack(alignment: .leading) {
                HStack(spacing: 16) {
                    let iconName = (gameType == .GenshinCN) ? "genshin_icon" : "zenless_icon"
                    Image(iconName)
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(width: 36, height: 36)
                    Text((gameType == .GenshinCN) ? "game.gi" : "game.zzz").font(.title2).bold()
                    Spacer()
                    Label("game.settings.uninstall", systemImage: "trash").foregroundStyle(.red)
                        .onTapGesture {
                            showDeleteGame = true
                        }
                }
                Divider()
                HStack {
                    Text("game.settings.location").font(.title3).bold()
                    Spacer()
                    Text(gameExec).font(.footnote).foregroundStyle(.secondary).monospaced()
                }.padding(.top, 32).padding(.bottom, 8)
                Button("game.settings.openIn", action: { GameSettings.openGameDirInFinder(gameExecPath: gameExec) }).padding(.bottom, 8)
                Button("game.settings.rechoose", action: reLocationGame)
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("game.settings.rechoose.tip", comment: ""), exeName)
                ).foregroundStyle(.secondary).font(.callout)
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

