//
//  WineRunner.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import Foundation

class WineRunner {
    private static let wine = LocalPaths.wineDir.appending(component: "wine").appending(component: "bin").appending(path: "wine")
    private static let environmentVar: [String : String] = ["WINEPREFIX": LocalPaths.prefixDir.toPath()]
    
    /// 通用的Wine运行函数
    static func runWineCmd(
        args: [String],
    ) throws -> ResultWineRunner {
        let process = Process()
        let pipe = Pipe()
        let env = environmentVar
        process.executableURL = wine
        process.arguments = args
        process.environment = env
        process.currentDirectoryURL = wine.deletingLastPathComponent()
        process.qualityOfService = .userInitiated
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        if let output = try pipe.fileHandleForReading.readToEnd() {
            let result = String(data: output, encoding: .utf8) ?? String()
            process.waitUntilExit()
            let status = process.terminationStatus
            return ResultWineRunner(outputData: result, retCode: status)
        } else {
            return ResultWineRunner()
        }
    }
}

extension WineRunner {
    static func gameStarter(
        gameType: GameType,
        gameExeFile: String,
        needMSync: Bool = true,
        needHUD: Bool = false
    ) throws {
        let process = Process()
        var env = environmentVar
        // 检查 MSYNC
        if needMSync {
            env.updateValue("1", forKey: "WINEMSYNC")
        }
        // 检查 HUD
        if needHUD {
            env.updateValue("1", forKey: "MTL_HUD_ENABLED")
        }
        process.executableURL = wine
        process.arguments = [gameExeFile]
        process.environment = env
        process.currentDirectoryURL = wine.deletingLastPathComponent()
        
        let startTime = Date()
        try process.run()
        process.terminationHandler = { pro in
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            DispatchQueue.main.async {
                let timerKey = "GameTime\(gameType.rawValue)"
                let lastGameTime = AppSettings.getPrefValue(key: timerKey, defVal: 0)
                AppSettings.setPrefValue(key: timerKey, val: Int(Int(duration) + lastGameTime))
            }
        }
    }
}

extension WineRunner {
    static func makeWineUsable() throws -> Int {
        let runResult = try runWineCmd(args: ["wineboot", "-u"])
        if runResult.retCode == -7350 {
            throw NSError(
                domain: "icu.bluedream.GenshinInstaller",
                code: 0x00000020,
                userInfo: [NSLocalizedDescriptionKey: "runnable.error.unknown"]
            )
        }
        return Int(runResult.retCode)
    }
}

extension WineRunner {
    static func changeRegValues(key: String, name: String, data: String, type: RegistryType) throws {
        _ = try runWineCmd(args: ["reg", "add", key, "-v", name, "-t", type.rawValue, "-d", data, "-f"])
    }
    
    /// 从注册表中获取值
    static func runWineReg(key: String, name: String, type: RegistryType) throws -> String? {
        let output = try runWineCmd(args: ["reg", "query", key, "-v", name])
        if output.retCode != 0 {
            return nil
        }
        let lines = output.outputData.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
        guard let line = lines.first(where: { $0.contains(type.rawValue) }) else { return nil }
        let array = line.split(omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
        guard let value = array.last else { return nil }
        return String(value)
    }
}

extension WineRunner {
    struct ResultWineRunner {
        let outputData: String
        let retCode: Int32
        
        init(outputData: String = "", retCode: Int32 = -7350) {
            self.outputData = outputData
            self.retCode = retCode
        }
    }
}

extension WineRunner {
    public static func isUsingRetinaMode() throws -> Bool {
        let values = ["y", "n"]
        guard let result = try runWineReg(key: WineInstaller.REG_MAC_DRIVER, name: "RetinaMode", type: .string),
              values.contains(result) else {
            try changeRegValues(key: WineInstaller.REG_MAC_DRIVER, name: "RetinaMode", data: "n", type: .string)
            return false
        }
        return result == "y"
    }
}

