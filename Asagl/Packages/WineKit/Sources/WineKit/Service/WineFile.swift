//
//  WineFile.swift
//  GenshinInstaller
//
//  Created by Yuan Shine on 2025/4/28.
//

import Foundation

extension WineKit {
    private static let tar = URL(fileURLWithPath: "/usr/bin/tar")
    
    /// 解压下载下来的wine压缩包
    public static func release2wineDir(source: URL, dest: URL) throws {
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
