//
//  Paths.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation
import AppKit

let rootPath = FileManager.default.urls(
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

extension URL {
    func toPath() -> String {
        return self.path(percentEncoded: false)
    }
}

class FileHelper {
    /// 检查文件是否存在
    static func checkExists(file: URL) -> Bool {
        return FileManager.default.fileExists(atPath: file.toPath())
    }
    
    /// 如果文件夹不存在 则创建（包括其他路径上的文件夹） 失败则抛出错误
    static func mkdir(dir: URL) throws {
        let fm = FileManager.default
        if !checkExists(file: dir) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
    
    /// 写入数据到文件
    static func writeData(data: Data, url: URL) {
        try! data.write(to: url)
    }
}

