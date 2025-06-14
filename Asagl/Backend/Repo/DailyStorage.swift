//
//  DailyStorage.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import Foundation

open class DailyStorage {
    var lastFetchDateKey: String
    
    init(lastFetchDateKey: String) {
        self.lastFetchDateKey = lastFetchDateKey
    }
    
    var shouldFetchToday: Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: lastFetchDateKey) as? Date else {
            return true
        }
        return !Calendar.current.isDateInToday(lastDate)
    }
    
    // 存储获取的日期和值
    func storeFetch(date: Date) {
        AppSettings.setPrefValue(key: lastFetchDateKey, val: date)
    }
}
