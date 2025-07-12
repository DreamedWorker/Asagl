//
//  HomeScreen.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/9.
//

import SwiftUI

struct HomeScreen: View {
    @AppStorage(AppConfigKey.PINNED_GAME) private var selectedGame: String = "hk4e_cn"
    @AppStorage(AppConfigKey.APP_FIRST_OPEN_VERSION) private var lastVersion: String = ""
    @State private var animatedSelectedGame: String = GameType.GenshinCN.rawValue
    @State private var uiPart: UIPart = .launcher
    
    var body: some View {
        if lastVersion == "2.0.0" {
            GeometryReader { geometry in
                ZStack {
                    LauncherBackgroundImg(windowSize: geometry.size, selectedGame: GameType.valueOf(name: animatedSelectedGame))
                    HStack {
                        VStack {
                            Image(systemName: "light.beacon.max")
                                .colorScheme(.dark)
                                .font(.system(size: 16))
                                .help("home.side.emergency")
                                .onTapGesture {
                                    WindowManager.shared.openEmergencyWindow()
                                }
                                .padding(.top, 32)
                                .padding(.bottom)
                            Image(systemName: "gear")
                                .colorScheme(.dark)
                                .font(.system(size: 16))
                                .padding(.bottom, 20)
                                .help("home.side.settings")
                                .onTapGesture {
                                    WindowManager.shared.openAppSettingsWindow()
                                }
                            Divider()
                            Image(systemName: "photo")
                                .colorScheme(.dark)
                                .font(.system(size: 16))
                                .padding(.top)
                                .help("home.side.screenshot")
                                .onTapGesture {
                                    withAnimation {
                                        uiPart = .gallery
                                    }
                                }
                            Spacer()
                            GameIcon(gameType: .GenshinCN, onClick: {
                                selectedGame = GameType.GenshinCN.rawValue
                                withAnimation {
                                    animatedSelectedGame = GameType.GenshinCN.rawValue
                                    uiPart = .launcher
                                }
                            })
                            GameIcon(gameType: .ZenlessCN, onClick: {
                                selectedGame = GameType.ZenlessCN.rawValue
                                withAnimation {
                                    animatedSelectedGame = GameType.ZenlessCN.rawValue
                                    uiPart = .launcher
                                }
                            })
                            .padding(.bottom, 20)
                        }
                        .background(Color.black)
                        .frame(width: 72)
                        // 活动部分
                        switch uiPart {
                        case .launcher:
                            VStack {
                                Spacer()
                                HStack(alignment: .bottom) {
                                    GameNewsPane(gameType: GameType.valueOf(name: selectedGame))
                                    Spacer()
                                    GameTimer(gameType: GameType.valueOf(name: selectedGame)) {
                                        return GameType.valueOf(name: selectedGame)
                                    }
                                    StartGameButton(gameType: GameType.valueOf(name: selectedGame))
                                }
                            }
                            .padding(.bottom, 20)
                            .padding(.horizontal, 20)
                        case .gallery:
                            GalleryView(gameType: GameType.valueOf(name: selectedGame))
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .onAppear {
                animatedSelectedGame = selectedGame
            }
        } else {
            WizardScreen {
                lastVersion = "2.0.0"
            }
        }
    }
    
    enum UIPart {
        case launcher
        case gallery
    }
}

#Preview {
    HomeScreen()
}
