//
//  FileHelper.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation

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
    
    /// 从应用内复制文件 如果文件存在则会删除之前的文件
    static func copyBundleFile2Disk(name: String, extensionName: String? = nil, needPermission: Bool = false) throws {
        // 获取其在应用内的路径
        guard let executableURL = Bundle.main.url(forResource: name, withExtension: extensionName) else {
            throw NSError()
        }
        let fileManager = FileManager.default
        // 开始复制
        let destinationURL = Paths.resourceDir.appending(path: executableURL.lastPathComponent)
        if fileManager.fileExists(atPath: destinationURL.toPath()) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: executableURL, to: destinationURL)
        if needPermission {
            // 设置可执行权限
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationURL.toPath())
            // 移除参数
            try removeQuarantine(path: destinationURL.toPath())
        }
    }
    
    /// 写入数据到文件
    static func writeData(data: Data, url: URL) {
        try! data.write(to: url)
    }
    
    static func fileMD5UsingSystemCommand(atPath path: String) -> String? {
        let task = Process()
        task.launchPath = "/sbin/md5"
        task.arguments = [path]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Output format is typically "MD5 (/path/to/file) = md5hash"
                let components = output.split(separator: " ")
                if components.count > 3, components[2] == "=" {
                    return String(components[3]).uppercased().replacingOccurrences(of: "\n", with: "")
                }
            }
        } catch {
            print("Error running command: \(error)")
        }
        return nil
    }
    
    private static func removeQuarantine(path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-s", "-r", "-d", "com.apple.quarantine", path]
        try process.run()
        process.waitUntilExit()
    }
}
