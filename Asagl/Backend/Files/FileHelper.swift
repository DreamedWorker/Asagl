//
//  FileHelper.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation

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
}
