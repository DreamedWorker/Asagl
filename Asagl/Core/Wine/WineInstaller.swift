//
//  WineInstaller.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import Foundation

class WineInstaller {
    static let REG_MAC_DRIVER = #"HKCU\Software\Wine\Mac Driver"#
    private static let tar = URL(fileURLWithPath: "/usr/bin/tar")
    
    static func installAndEnableWine(temp: URL, wineDir: URL, wineTarName: String = "wine.tar.gz") throws {
        // 将下载的临时文件解压并固定
        try release2wineDir(source: temp, dest: wineDir)
        let innerFile = wineDir.appending(component: wineTarName)
        if FileManager.default.fileExists(atPath: innerFile.path(percentEncoded: false)) {
            try! FileManager.default.removeItem(at: innerFile)
        }
        try FileManager.default.moveItem(at: temp, to: innerFile)
        // 开始配置Wine
        _ = try WineRunner.makeWineUsable()
        try WineRunner.changeRegValues(key: REG_MAC_DRIVER, name: "RetinaMode", data: "n", type: .string)
        // 完成配置
    }
    
    static func backupOriginalPrefix() throws {
        let backupFolder = LocalPaths.resourceDir.appending(component: "WinePrefixBak")
        if FileManager.default.fileExists(atPath: backupFolder.toPath()) {
            try FileManager.default.removeItem(at: backupFolder)
        }
        try FileManager.default.copyItem(at: LocalPaths.prefixDir, to: backupFolder)
    }
    
    /// 解压下载下来的wine压缩包
    private static func release2wineDir(source: URL, dest: URL) throws {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = tar
        process.arguments = ["-xzf", "\(source.path)", "-C", "\(dest.path)"]
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        if let output = try pipe.fileHandleForReading.readToEnd() {
            let outputString = String(data: output, encoding: .utf8) ?? String()
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                throw NSError(domain: "WineInstaller", code: -1, userInfo: [NSLocalizedDescriptionKey: outputString])
            }
        }
    }
}

