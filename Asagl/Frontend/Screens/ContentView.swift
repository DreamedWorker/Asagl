//
//  ContentView.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(AppConfigKey.APP_FIRST_OPEN_VERSION) private var lastVersion: String = ""
    @AppStorage(AppConfigKey.PINNED_GAME) private var selectedGame: String = "hk4e_cn"
    @State private var showUpdateSheet = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    LauncherImage(size: geo.size, selectedGame: selectedGame)
                    HStack {
                        SideGamesBar(changeGame: { game in selectedGame = game })
                        VStack {
                            Spacer()
                            HStack(alignment: .bottom) {
                                GameNewsPane(gameType: .valueOf(name: selectedGame))
                                Spacer()
                                StartGameButton(gameType: .valueOf(name: selectedGame))
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .onAppear {
            if lastVersion != "1.0.0" {
                showUpdateSheet = true
            }
        }
        .onChange(of: lastVersion, { _, newOne in
            showUpdateSheet = newOne != "1.0.0"
        })
        .sheet(isPresented: $showUpdateSheet) {
            WizardView(
                refreshVersion: {
                    lastVersion = "1.0.0"
                }
            )
            .interactiveDismissDisabled(true)
        }
    }
}

fileprivate struct SideGamesBar: View {
    let changeGame: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            GameIcon(iconName: "genshin_icon", onClick: {
                withAnimation {
                    changeGame("hk4e_cn")
                }
            })
            .help("home.side.gi")
            .padding(.top, 50)
            GameIcon(iconName: "zenless_icon", onClick: {
                withAnimation {
                    changeGame("nap_cn")
                }
            }).help("home.side.zzz")
            Spacer()
        }
        .frame(width: 72)
        .background(.regularMaterial)
    }
}

fileprivate struct GameIcon: View {
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
