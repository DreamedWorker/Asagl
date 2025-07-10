//
//  GameSettingsWindow.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/10.
//

import SwiftUI

struct GameSettingsWindow: View {
    @State private var uiPart: UIPart = .basic
    let gameType: GameType
    let refreshGameState: () -> Void
    let relocationGame: () -> Void
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(selection: $uiPart) {
                    NavigationLink(
                        value: UIPart.basic,
                        label: { Label("game.settings.tab.baisc", systemImage: "info.circle") }
                    )
                    NavigationLink(
                        value: UIPart.update,
                        label: { Label("game.settings.tab.update", systemImage: "square.and.arrow.down.on.square") }
                    )
                }
            },
            detail: {
                switch uiPart {
                case .basic:
                    GameBasicSettingsPane(gameType: gameType, refreshGameState: refreshGameState, reLocationGame: relocationGame)
                        .navigationTitle(Text("game.settings.tab.baisc"))
                case .update:
                    GameUpdatePane(gameType: gameType)
                        .navigationTitle(Text("game.settings.tab.update"))
                }
            }
        )
    }
    
    enum UIPart {
        case basic
        case update
    }
}
