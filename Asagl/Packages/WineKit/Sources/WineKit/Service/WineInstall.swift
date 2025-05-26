//
//  WineInstall.swift
//  WineKit
//
//  Created by Yuan Shine on 2025/5/25.
//

import Foundation

extension WineKit {
    static let REG_MAC_DRIVER = #"HKCU\Software\Wine\Mac Driver"#
    
    public static func installAndEnableWine(temp: URL, wineDir: URL) throws {
        // 将下载的临时文件解压并固定
        try release2wineDir(source: temp, dest: wineDir)
        let innerFile = wineDir.appending(component: "wine.tar.gz")
        if FileManager.default.fileExists(atPath: innerFile.path(percentEncoded: false)) {
            try! FileManager.default.removeItem(at: innerFile)
        }
        try FileManager.default.moveItem(at: temp, to: innerFile)
        // 开始配置Wine
        _ = try makeWineUsable()
        try changeRegValues(key: REG_MAC_DRIVER, name: "RetinaMode", data: "n", type: .string)
        // 完成配置
    }
}
