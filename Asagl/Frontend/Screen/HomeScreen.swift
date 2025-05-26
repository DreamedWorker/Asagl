//
//  HomeScreen.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import SwiftUI
import Kingfisher
import GameKit

struct HomeScreen: View {
    @StateObject private var svm = SharedViewModel.shared
    @State private var selectedGame: GameKit.GameType = .valueOf(name: AppSettings.getPrefValue(key: AppConfigKey.PINNED_GAME, defVal: "hk4e_cn"))
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    if let launcherInfo = viewModel.launcherInfo {
                        let bga = launcherInfo.data.gameInfoList.filter({ $0.game.biz == selectedGame.rawValue }).first!
                        if !bga.backgrounds.isEmpty {
                            let bg = bga.backgrounds[0].background.url
                            KFImage
                                .url(URL(string: bg)!)
                                .loadDiskFileSynchronously(true)
                                .resizable()
                                .aspectRatio(1.7, contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                        } else {
                            Image((selectedGame == .GenshinCN) ? "genshin_bg" : "zenless_bg")
                                .resizable()
                                .aspectRatio(1.7, contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    } else {
                        Image((selectedGame == .GenshinCN) ? "genshin_bg" : "zenless_bg")
                            .resizable()
                            .aspectRatio(1.7, contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    HStack {
                        // 侧栏 -- 游戏切换
                        VStack(spacing: 16) {
                            GameIcon(iconName: "genshin_icon", onClick: {
                                withAnimation(.easeInOut, {
                                    selectedGame = .GenshinCN
                                })
                            }).help("home.side.gi")
                            GameIcon(iconName: "zenless_icon", onClick: {
                                withAnimation(.easeInOut, {
                                    selectedGame = .ZenlessCN
                                })
                            }).help("home.side.zzz")
                            Spacer()
                            ZStack(alignment: .center, content: {
                                Image(systemName: "pin.fill")
                                    .resizable()
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .frame(width: 48, height: 48)
                            })
                            .help("home.side.default")
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.black.opacity(0.5)))
                            .onTapGesture {
                                AppSettings.setPrefValue(key: AppConfigKey.PINNED_GAME, val: selectedGame.rawValue)
                                svm.sendGlobalMessage(context: NSLocalizedString("home.info.changePin", comment: ""), msgType: .Info)
                            }
                        }
                        .frame(width: 72)
                        .padding(.top, 50)
                        .background(.black.opacity(0.5))
                        // 主体功能区
                        VStack {
                            Spacer()
                            HStack(alignment: .bottom) {
                                GameNewsPane(gameType: selectedGame)
                                Spacer()
                                StartGameButton(gameType: selectedGame)
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.tryFetchInfoOrNil()
            }
        }
    }
}

extension HomeScreen {
    struct GameIcon: View {
        let iconName: String
        let onClick: () -> Void
        @State private var isHovering = false
        
        var body: some View {
            Image(iconName)
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(width: 48, height: 48)
                .scaleEffect(isHovering ? 1.2 : 1.0)
                .shadow(color: isHovering ? .black.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
                .onHover { hovering in isHovering = hovering }
                .onTapGesture { onClick() }
        }
    }
}
