//
//  LauncherImage.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import SwiftUI
import Kingfisher

struct LauncherImage: View {
    @StateObject private var viewModel = BgService()
    let size: CGSize
    let selectedGame: String
    
    var body: some View {
        if let launcherInfo = viewModel.launcherInfo {
            let bga = launcherInfo.data.gameInfoList.filter({ $0.game.biz == selectedGame }).first!
            if !bga.backgrounds.isEmpty {
                let bg = bga.backgrounds[0].background.url
                KFImage
                    .url(URL(string: bg)!)
                    .loadDiskFileSynchronously(true)
                    .resizable()
                    .aspectRatio(1.7, contentMode: .fill)
                    .frame(width: size.width, height: size.height)
            } else {
                Image((selectedGame == "hk4e_cn") ? "genshin_bg" : "zenless_bg")
                    .resizable()
                    .aspectRatio(1.7, contentMode: .fill)
                    .frame(width: size.width, height: size.height)
            }
        } else {
            Image((selectedGame == "hk4e_cn") ? "genshin_bg" : "zenless_bg")
                .resizable()
                .aspectRatio(1.7, contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .onAppear {
                    Task {
                        await viewModel.tryFetchInfoOrNil()
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
