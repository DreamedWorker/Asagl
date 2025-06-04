//
//  Locales.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation

// 从系统设置中取值用户当前的所在国家
func isInChina() -> Bool {
    return Locale.autoupdatingCurrent.identifier.contains("CN")
}

//func timestamp2string(another: Bool = false) -> String {
//    let timestamp = another ? TimeInterval(AppSettings.getPrefValue(key: AppConfigKey.LAST_FETCHED_LAUNCHER_INFO, defVal: 0)) :
//    TimeInterval(AppSettings.getPrefValue(key: AppConfigKey.LAST_FETCHED_GAME_INFO, defVal: 0))
//    let date = Date(timeIntervalSince1970: timestamp)
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//    return dateFormatter.string(from: date)
//}
