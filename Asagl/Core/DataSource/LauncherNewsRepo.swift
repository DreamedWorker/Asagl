//
//  LauncherNewsRepo.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import Foundation

class LauncherNewsRepo: DailyStorage {
    let WEBSTATIC_GENSHIN_NEWS = "https://hyp-api.mihoyo.com/hyp/hyp-connect/api/getGameContent?launcher_id=jGHBHlcOq1&language=zh_CN&game_id=1Z8W5NHUQb"
    let WEBSTATIC_ZENLESS_NEWS = "https://hyp-api.mihoyo.com/hyp/hyp-connect/api/getGameContent?launcher_id=jGHBHlcOq1&language=zh_CN&game_id=x6znKlJ0xK"
    private let gameType: GameType
    
    init(configKey: String, type: GameType) {
        self.gameType = type
        super.init(lastFetchDateKey: configKey)
    }
    
    func fetchFromNetwork() async throws -> LauncherNews {
        let url = URL(string: (gameType == .GenshinCN) ? WEBSTATIC_GENSHIN_NEWS : WEBSTATIC_ZENLESS_NEWS)!
        let (data, _) = try await URLSession.shared.data(from: url)
        FileHelper.writeData(data: data, url: LocalPaths.path(front: LocalPaths.resourceDir.toPath(), relative: "\(gameType.rawValue)_news.json"))
        let formattedOne = try JSONDecoder().decode(LauncherNews.self, from: data)
        storeFetch(date: Date())
        return formattedOne
    }
    
    func fetchFromDisk() -> LauncherNews? {
        let formattedOne = try? JSONDecoder()
            .decode(
                LauncherNews.self,
                from: Data(contentsOf: LocalPaths.path(front: LocalPaths.resourceDir.toPath(), relative: "\(gameType.rawValue)_news.json"))
            )
        return formattedOne
    }
}
