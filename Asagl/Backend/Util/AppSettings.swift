//
//  AppSettings.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import Foundation

class AppSettings {
    static func setPrefValue<T>(key: String, val: T) {
        UserDefaults.standard.set(val, forKey: key)
    }
    
    static func getPrefValue<T>(key: String, defVal: T) -> T {
        return UserDefaults.standard.object(forKey: key) as? T ?? defVal
    }
}

struct AppConfigKey {
    static let APP_FIRST_OPEN_VERSION = "firstOpenedVersion"
    static let LAST_FETCHED_LAUNCHER_INFO = "lastLauncherInfoFetchedTime"
    static let LAST_FETCHED_GAME_INFO = "lastGameInfoFetchedTime"
    static let PINNED_GAME = "pinnedGame"
    static let USING_MSYNC = "usingMsync"
    static let USING_HUD = "usingMetalHUD"
    static let USING_AB = "usingAutoBlock"
    static let HAS_GAME_SETUP = "hasGameSetup"
    static let GAME_EXECUTABLE_FILE = "gameExecutableFileLocation"
    static let LAST_FETCHED_LAUNCHER_NEWS = "lastLauncherNewsFetchedTime"
    
    static let GENSHIN_EXEC_PATH = "genshinExecPath"
    static let ZENLESS_EXEC_PATH = "zenlessExecPath"
}
