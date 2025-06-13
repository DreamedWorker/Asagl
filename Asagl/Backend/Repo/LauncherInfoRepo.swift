//
//  LauncherInfoRepo.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import Foundation

class LauncherInfoRepo: DailyStorage {
    private let WEBSTATIC_LAUNCHER_BGS = "https://hyp-api.mihoyo.com/hyp/hyp-connect/api/getAllGameBasicInfo?launcher_id=jGHBHlcOq1"
    private let FILE_NAME = "LauncherBgs.json"
    
    init(configKey: String) {
        super.init(lastFetchDateKey: configKey)
    }
    
    func fetchFromNetwork() async throws -> LauncherBasic {
        let data = try await AsaglEndpoint.simpleGET(url: WEBSTATIC_LAUNCHER_BGS)
        FileHelper.writeData(data: data, url: LocalPaths.path(front: LocalPaths.resourceDir.toPath(), relative: FILE_NAME))
        let formattedOne = try JSONDecoder().decode(LauncherBasic.self, from: data)
        storeFetch(date: Date())
        return formattedOne
    }
    
    func fetchFromDisk() -> LauncherBasic? {
        let formattedOne = try? JSONDecoder()
            .decode(
                LauncherBasic.self,
                from: Data(contentsOf: LocalPaths.path(front: LocalPaths.resourceDir.toPath(), relative: FILE_NAME))
            )
        return formattedOne
    }
}

extension LauncherInfoRepo {
    struct LauncherBasic: Codable {
        let retcode: Int
        let message: String
        let data: DataClass
    }
}

extension LauncherInfoRepo.LauncherBasic {
    struct DataClass: Codable {
        let gameInfoList: [GameInfoList]
        
        enum CodingKeys: String, CodingKey {
            case gameInfoList = "game_info_list"
        }
    }
    
    struct GameInfoList: Codable {
        let game: Game
        let backgrounds: [BackgroundElement]
    }
    
    struct BackgroundElement: Codable {
        let id: String
        let background: BackgroundBackground
        let icon: Icon
    }
    
    struct BackgroundBackground: Codable {
        let url: String
        let link: String
        let loginStateInLink: Bool
        
        enum CodingKeys: String, CodingKey {
            case url, link
            case loginStateInLink = "login_state_in_link"
        }
    }
    
    struct Icon: Codable {
        let url, hoverURL: String
        let link: String
        let loginStateInLink: Bool
        let md5: String
        let size: Int
        
        enum CodingKeys: String, CodingKey {
            case url
            case hoverURL = "hover_url"
            case link
            case loginStateInLink = "login_state_in_link"
            case md5, size
        }
    }
    
    struct Game: Codable {
        let id, biz: String
    }

}
