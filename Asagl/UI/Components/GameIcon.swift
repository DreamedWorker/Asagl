//
//  GameIcon.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/10.
//

import SwiftUI

struct GameIcon: View {
    let gameType: GameType
    let onClick: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing, content: {
            Image("\(gameType.rawValue)_icon")
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(width: 48, height: 48)
            if gameType.rawValue.contains("_cn") {
                Image("region_hyperion")
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .frame(width: 16, height: 16)
            }
        })
        .help(NSLocalizedString("gametype.\(gameType.rawValue)", comment: ""))
        .frame(width: 48, height: 48)
        .onTapGesture { onClick() }
    }
}
