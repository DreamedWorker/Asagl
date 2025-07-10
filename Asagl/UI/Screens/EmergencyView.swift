//
//  EmergencyView.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/10.
//

import SwiftUI

struct EmergencyView: View {
    @StateObject private var emeViewModel = EmergencyViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("emergency.title").font(.largeTitle.bold()).foregroundStyle(.red)
            Text("eme.exp").foregroundStyle(.secondary).padding(.bottom)
            Toggle("wizard.download.mirror", isOn: $emeViewModel.useMirror)
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(.bottom, 8)
            HStack {
                Button("eme.start", action: {
                    emeViewModel.repairEnv()
                })
                .buttonStyle(.borderedProminent)
                .disabled(emeViewModel.disableDownloadBtn)
                Button("eme.start.full", action: {
                    emeViewModel.doFullRepair()
                })
            }
            Divider()
            Button("eme.dl.dll", action: {
                emeViewModel.showWineDownloadBar = true
                Task {
                    await emeViewModel.downloadDll()
                }
            })
            
            if emeViewModel.showWineDownloadBar {
                VStack {
                    ProgressView(value: emeViewModel.downloadingProgress, total: 1)
                    HStack {
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("wizard.download.progress", comment: ""),
                                formatBytes2ReadableString(bytes: emeViewModel.completedBytes),
                                formatBytes2ReadableString(bytes: emeViewModel.totalBytes)
                            )
                        ).font(.subheadline).monospacedDigit()
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .navigationTitle(Text("emergency.title"))
        .padding(20)
        .alert(
            emeViewModel.alertMate.title,
            isPresented: $emeViewModel.alertMate.showIt,
            actions: {},
            message: { Text(emeViewModel.alertMate.msg) }
        )
    }
    
    func formatBytes2ReadableString(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
    }
}

fileprivate class EmergencyViewModel: ObservableObject, @unchecked Sendable {
    @Published var useMirror: Bool = Locale.autoupdatingCurrent.identifier.contains("CN")
    @Published var downloadingProgress: Double = 0
    @Published var completedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var disableDownloadBtn = false
    @Published var alertMate: AlertMate = .init()
    @Published var showWineDownloadBar: Bool = false
    
    func repairEnv() {
        let wine = LocalPaths.wineDir.appending(component: "wine").appending(component: "bin").appending(path: "wine")
        if FileManager.default.fileExists(atPath: wine.toPath()) {
            doEasyRepair()
        } else {
            doFullRepair()
        }
    }
    
    private func doEasyRepair() {
        Task {
            do {
                if FileManager.default.fileExists(atPath: LocalPaths.prefixDir.toPath()) {
                    try FileManager.default.removeItem(at: LocalPaths.prefixDir)
                }
                try FileManager.default.createDirectory(at: LocalPaths.prefixDir, withIntermediateDirectories: true)
                _ = try WineRunner.makeWineUsable()
                try? WineRunner.changeRegValues(key: #"HKCU\Software\Wine\Mac Driver"#, name: "RetinaMode", data: "n", type: .string)
                DispatchQueue.main.async {
                    self.alertMate.showAlert(msg: NSLocalizedString("eme.info.repairOK", comment: ""))
                }
            } catch {
                doFullRepair()
            }
        }
    }
    
    func downloadDll() async {
        let dllURL = useMirror ?
        "https://ghproxy.net/https://github.com/DreamedWorker/wine/releases/download/wine10.0/kernelbase.dll"
        : "https://github.com/DreamedWorker/wine/releases/download/wine10.0/kernelbase.dll"
        let downloadManager = DownloadManager(
            process: { process, cur, tot in
                Task {
                    await MainActor.run {
                        if 0.0...1.0 ~= process {
                            self.downloadingProgress = process
                        }
                        self.completedBytes = cur
                        self.totalBytes = tot
                    }
                }
            }
        )
        downloadManager.startDownload(
            url: dllURL,
            finished: { temp in
                Task {
                    do {
                        let targetFile = LocalPaths.resourceDir.appending(component: "kernelbase.dll")
                        if FileHelper.checkExists(file: targetFile) {
                            try FileManager.default.removeItem(at: targetFile)
                        }
                        try FileManager.default.moveItem(at: temp, to: targetFile)
                        await MainActor.run {
                            self.showWineDownloadBar = false
                        }
                    } catch {
                        await MainActor.run {
                            self.alertMate.showAlert(msg: "Failed to download Dll，\(error.localizedDescription)", type: .Error)
                            self.showWineDownloadBar = false
                        }
                    }
                }
            },
            sendError: { msg in
                DispatchQueue.main.async {
                    self.alertMate.showAlert(msg: msg, type: .Error)
                    self.showWineDownloadBar = false
                }
            }
        )
    }
    
    func doFullRepair() {
        Task {
            do {
                // 删除 wine 和 prefix
                let filemgr = FileManager.default
                if filemgr.fileExists(atPath: LocalPaths.prefixDir.toPath()) {
                    try filemgr.removeItem(at: LocalPaths.prefixDir)
                }
                if filemgr.fileExists(atPath: LocalPaths.wineDir.toPath()) {
                    try filemgr.removeItem(at: LocalPaths.wineDir)
                }
                try filemgr.createDirectory(at: LocalPaths.wineDir, withIntermediateDirectories: true)
                try filemgr.createDirectory(at: LocalPaths.prefixDir, withIntermediateDirectories: true)
                // 重新下载
                let wineURL = useMirror ?
                "https://ghproxy.net/https://github.com/DreamedWorker/wine/releases/download/wine10.10/wine10.10.tar.gz"
                : "https://github.com/DreamedWorker/wine/releases/download/wine10.10/wine10.10.tar.gz"
                let downloadManager = DownloadManager(
                    process: { process, cur, tot in
                        Task {
                            await MainActor.run {
                                if 0.0...1.0 ~= process {
                                    self.downloadingProgress = process
                                }
                                self.completedBytes = cur
                                self.totalBytes = tot
                            }
                        }
                    }
                )
                downloadManager.startDownload(
                    url: wineURL,
                    finished: { temp in
                        Task {
                            do {
                                try WineInstaller.installAndEnableWine(temp: temp, wineDir: LocalPaths.wineDir)
                                let versionFile = LocalPaths.wineDir.appending(component: "version.txt")
                                try "10.10.0".data(using: .utf8)!.write(to: versionFile)
                                await MainActor.run {
                                    self.showWineDownloadBar = false
                                }
                            } catch {
                                await MainActor.run {
                                    self.alertMate.showAlert(msg: "Failed to download Wine，\(error.localizedDescription)", type: .Error)
                                    self.disableDownloadBtn = false
                                    self.showWineDownloadBar = false
                                }
                            }
                        }
                    },
                    sendError: { _ in
                        DispatchQueue.main.async {
                            self.alertMate.showAlert(msg: NSLocalizedString("eme.failed", comment: ""), type: .Error)
                            self.disableDownloadBtn = false
                        }
                    }
                )
            }
        }
    }
}
