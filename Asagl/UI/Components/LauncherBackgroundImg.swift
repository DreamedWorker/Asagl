//
//  LauncherBackgroundImg.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/9.
//

import SwiftUI
import Kingfisher

struct LauncherBackgroundImg: View {
    let windowSize: CGSize
    let selectedGame: GameType
    @StateObject private var lbService = BgService()
    
    var body: some View {
        if let launcherInfo = lbService.launcherInfo {
            let bga = launcherInfo.data.gameInfoList.filter({ $0.game.biz == selectedGame.rawValue }).first!
            if !bga.backgrounds.isEmpty {
                let bg = bga.backgrounds[0].background.url
                KFImage
                    .url(URL(string: bg)!)
                    .loadDiskFileSynchronously(true)
                    .resizable()
                    .frame(width: windowSize.width, height: windowSize.height)
            } else {
                Image((selectedGame.rawValue == "hk4e_cn") ? "genshin_bg" : "zenless_bg")
                    .resizable()
                    .frame(width: windowSize.width, height: windowSize.height)
            }
        } else {
            Image((selectedGame.rawValue == "hk4e_cn") ? "genshin_bg" : "zenless_bg")
                .resizable()
                .frame(width: windowSize.width, height: windowSize.height)
                .onAppear {
                    Task {
                        await lbService.tryFetchInfoOrNil()
                    }
                }
        }
    }
}

fileprivate class BgService: ObservableObject, @unchecked Sendable {
    @Published var launcherInfo: LauncherInfoRepo.LauncherBasic? = nil
    let dailyStorage: LauncherInfoRepo = .init(configKey: "LauncherBackgroundFetchDate")
    
    func tryFetchInfoOrNil() async {
        if dailyStorage.shouldFetchToday {
            let result = try? await dailyStorage.fetchFromNetwork()
            DispatchQueue.main.async {
                self.launcherInfo = result
            }
        } else {
            let result = dailyStorage.fetchFromDisk()
            DispatchQueue.main.async {
                self.launcherInfo = result
            }
        }
    }
}
