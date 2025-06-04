//
//  HomeViewModel.swift
//  Yahgs
//
//  Created by Yuan Shine on 2025/5/7.
//

import Foundation

class HomeViewModel: ObservableObject, @unchecked Sendable {
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
