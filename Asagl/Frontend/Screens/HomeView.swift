//
//  HomeView.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/6/4.
//

import SwiftUI
import GameKit
import Kingfisher

struct HomeView: View {
    @StateObject private var svm = SharedViewModel.shared
    @AppStorage(AppConfigKey.PINNED_GAME) private var selectedGame: String = "hk4e_cn"
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    if let launcherInfo = viewModel.launcherInfo {
                        let bga = launcherInfo.data.gameInfoList.filter({ $0.game.biz == selectedGame }).first!
                        if !bga.backgrounds.isEmpty {
                            let bg = bga.backgrounds[0].background.url
                            KFImage
                                .url(URL(string: bg)!)
                                .loadDiskFileSynchronously(true)
                                .resizable()
                                .aspectRatio(1.7, contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                        } else {
                            Image((selectedGame == "hk4e_cn") ? "genshin_bg" : "zenless_bg")
                                .resizable()
                                .aspectRatio(1.7, contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    } else {
                        Image((selectedGame == "hk4e_cn") ? "genshin_bg" : "zenless_bg")
                            .resizable()
                            .aspectRatio(1.7, contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    HStack {
                        VStack(spacing: 16) {
                            GameIcon(iconName: "genshin_icon", onClick: {
                                withAnimation(.easeInOut, {
                                    selectedGame = "hk4e_cn"
                                })
                            }).help("home.side.gi")
                            GameIcon(iconName: "zenless_icon", onClick: {
                                withAnimation(.easeInOut, {
                                    selectedGame = "nap_cn"
                                })
                            }).help("home.side.zzz")
                            Spacer()
                        }
                        .frame(width: 72)
                        .padding(.top, 50)
                        .background(.black.opacity(0.5))
                        VStack {
                            Spacer()
                            HStack(alignment: .bottom) {
                                GameNewsPane(gameType: .valueOf(name: selectedGame))
                                Spacer()
                                StartGameButton(gameType: .valueOf(name: selectedGame))
                            }
                            .padding(20)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.tryFetchInfoOrNil()
            }
        }
    }
}

extension HomeView {
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
