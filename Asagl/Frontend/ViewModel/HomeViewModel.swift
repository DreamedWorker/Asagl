//
//  HomeViewModel.swift
//  Yahgs
//
//  Created by Yuan Shine on 2025/5/7.
//

import Foundation

class HomeViewModel: ObservableObject {
    @Published var launcherInfo: LauncherInfoRepo.LauncherBasic? = nil
    private let svm = SharedViewModel.shared
    
    let dailyStorage = GlobalUsed.launcherBg
    
    func tryFetchInfoOrNil() {
        // 因为在应用启动时会尝试从互联网访问 故这里只从磁盘读取
        launcherInfo = dailyStorage.fetchFromDisk()
    }
}
