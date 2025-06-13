//
//  Paths.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation
import AppKit

fileprivate let rootPath = FileManager.default.urls(
    for: .applicationSupportDirectory, in: .userDomainMask
)[0].appending(component: Bundle.main.bundleIdentifier!)

class LocalPaths {
    /// 下载路径
    static let resourceDir = rootPath.appending(components: "GameResource")
    /// Wine的可执行文件路径
    static let wineDir = rootPath.appending(components: "Wine")
    /// WINEPREFIX 路径
    static let prefixDir = rootPath.appending(components: "Prefix")
    
    /// 通过前方的绝对路径和后方的相对路径来拼凑路径
    static func path(front: String, relative: String) -> URL {
        return URL(fileURLWithPath: front).appending(components: relative)
    }
    
    /// 检查文件夹环境 仅在应用启动时执行 如果失败则阻止启动
    static func checkDirs() {
        do {
            try FileHelper.mkdir(dir: resourceDir)
            try FileHelper.mkdir(dir: wineDir)
            try FileHelper.mkdir(dir: prefixDir)
        } catch {
            DispatchQueue.main.async {
                NSApplication.shared.terminate(self)
            }
        }
    }
}
