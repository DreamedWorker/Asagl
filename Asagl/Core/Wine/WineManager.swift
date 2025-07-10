//
//  WineManager.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/9.
//

import Foundation

class WineManager {
    private static let wineExecutableFile = LocalPaths.wineDir.appending(components: "wine")
        .appending(component: "bin").appending(component: "wine")
    static func hasWineDownloaded() -> Bool {
        return FileManager.default.fileExists(atPath: LocalPaths.wineDir.appending(component: "wine.tar.gz").toPath())
    }
    
    static func hasWineInstalled() -> Bool {
        let filemgr = FileManager.default
        return filemgr.fileExists(atPath: wineExecutableFile.toPath()) &&
        filemgr.fileExists(atPath: LocalPaths.prefixDir.appending(component: "user.reg").toPath())
    }
}

extension WineManager {
    static func hasReplaceDllFounded() -> Bool {
        return FileManager.default.fileExists(atPath: LocalPaths.resourceDir.appending(component: "kernelbase.dll").toPath())
    }
}
