//
//  WizardScreen.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/9.
//

import SwiftUI

struct WizardScreen: View {
    @StateObject private var wizardViewModel = WizardViewModel()
    @State private var dlModeSelector = false
    
    let changeVersion: () -> Void
    
    init(changeVersion: @escaping () -> Void) {
        self.changeVersion = changeVersion
    }
    
    var body: some View {
        VStack {
            Image("logo").resizable().frame(width: 72, height: 72)
            Text("wizard.title").font(.largeTitle.bold())
            Text("wizard.exp").foregroundStyle(.secondary).padding(.bottom)
            // 数据文件夹位置提示
            VStack {
                HStack(spacing: 20) {
                    Image(systemName: "folder")
                        .font(.title2)
                    Text("wizard.folder.title").font(.title2.bold())
                    Spacer()
                }
                Text(String.localizedStringWithFormat(NSLocalizedString("wizard.folder.exp", comment: ""), rootPath.toPath()))
                    .foregroundStyle(.secondary).monospaced()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.background))
            Form {
                // wine 安装情况
                Section {
                    VStack {
                        HStack {
                            Label("wizard.form.wineInstallStatus", systemImage: "wineglass")
                            Spacer()
                            HStack(spacing: 8) {
                                Text(NSLocalizedString(wizardViewModel.wineStatus.rawValue, comment: ""))
                                    .foregroundStyle(.secondary)
                                if wizardViewModel.wineStatus == .nothing {
                                    Button("wizard.form.download", action: { dlModeSelector = true })
                                        .disabled(wizardViewModel.disableDownloadBtn)
                                }
                            }
                        }.onAppear {
                            wizardViewModel.checkWineStatus()
                        }
                        if wizardViewModel.showWineDownloadBar {
                            VStack {
                                ProgressView(value: wizardViewModel.downloadingProgress, total: 1)
                                HStack {
                                    Text(
                                        String.localizedStringWithFormat(
                                            NSLocalizedString("wizard.download.progress", comment: ""),
                                            formatBytes2ReadableString(bytes: wizardViewModel.completedBytes),
                                            formatBytes2ReadableString(bytes: wizardViewModel.totalBytes)
                                        )
                                    ).font(.subheadline).monospacedDigit()
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .alert("wizard.form.dlMode", isPresented: $dlModeSelector, actions: {
                    Button("wizard.download.mirror", action: {
                        wizardViewModel.useMirror = true
                        dlModeSelector = false
                        wizardViewModel.showWineDownloadBar = true
                        wizardViewModel.disableDownloadBtn = true
                        Task {
                            await wizardViewModel.downloadWineAndInstall()
                        }
                    })
                    Button("wizard.download.directly", action: {
                        wizardViewModel.useMirror = false
                        dlModeSelector = false
                        wizardViewModel.showWineDownloadBar = true
                        wizardViewModel.disableDownloadBtn = true
                        Task {
                            await wizardViewModel.downloadWineAndInstall()
                        }
                    })
                    Button("def.cancel", role: .cancel, action: { dlModeSelector = false })
                })
                Section {
                    // dll 替换本存在情况
                    VStack {
                        HStack {
                            Label("wizard.form.dllInstallStatus", systemImage: "building.columns")
                            Spacer()
                            HStack(spacing: 8) {
                                Text(NSLocalizedString(wizardViewModel.dllStatus.rawValue, comment: ""))
                                    .foregroundStyle(.secondary)
                                if wizardViewModel.dllStatus == .nothing {
                                    Button("wizard.form.download", action: {
                                        wizardViewModel.showDllDownloadBar = true
                                        Task {
                                            await wizardViewModel.downloadDll()
                                        }
                                    })
                                }
                            }
                        }.onAppear {
                            wizardViewModel.checkDllStatus()
                        }
                        if wizardViewModel.showDllDownloadBar {
                            VStack {
                                ProgressView(value: wizardViewModel.downloadingProgress, total: 1)
                                HStack {
                                    Text(
                                        String.localizedStringWithFormat(
                                            NSLocalizedString("wizard.download.progress", comment: ""),
                                            formatBytes2ReadableString(bytes: wizardViewModel.completedBytes),
                                            formatBytes2ReadableString(bytes: wizardViewModel.totalBytes)
                                        )
                                    ).font(.subheadline).monospacedDigit()
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }.formStyle(.grouped)
            if wizardViewModel.wineStatus == .installed {
                Button(
                    action: changeVersion,
                    label: {
                        Text("wizard.start")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }
                ).buttonStyle(.borderedProminent)
            }
            Spacer()
            Text("wizard.importance").font(.footnote).foregroundStyle(.secondary)
        }
        .padding(20)
        .alert(
            wizardViewModel.alertMate.title,
            isPresented: $wizardViewModel.alertMate.showIt,
            actions: {},
            message: { Text(wizardViewModel.alertMate.msg) }
        )
    }
    
    func formatBytes2ReadableString(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
    }
}

fileprivate class WizardViewModel: ObservableObject, @unchecked Sendable {
    @Published var wineStatus: WineStatus = .nothing
    @Published var dllStatus: WineStatus = .nothing
    @Published var showWineDownloadBar: Bool = false
    @Published var showDllDownloadBar: Bool = false
    @Published var useMirror: Bool = Locale.autoupdatingCurrent.identifier.contains("CN")
    @Published var downloadingProgress: Double = 0
    @Published var completedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var disableDownloadBtn = false
    @Published var alertMate: AlertMate = .init()
    
    enum WineStatus: String {
        case nothing = "wizard.form.wineNotInstalled"
        case downloaded = "wizard.form.wineDownloaded"
        case installed = "wizard.form.wineInstalled"
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
                            self.showDllDownloadBar = false
                            self.checkDllStatus()
                        }
                    } catch {
                        await MainActor.run {
                            self.alertMate.showAlert(msg: "Failed to download Dll，\(error.localizedDescription)", type: .Error)
                            self.showDllDownloadBar = false
                            self.dllStatus = .nothing
                        }
                    }
                }
            },
            sendError: { msg in
                DispatchQueue.main.async {
                    self.alertMate.showAlert(msg: msg, type: .Error)
                    self.showDllDownloadBar = false
                    self.dllStatus = .nothing
                }
            }
        )
    }
    
    func downloadWineAndInstall() async {
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
                            self.wineStatus = .installed
                        }
                    } catch {
                        await MainActor.run {
                            self.alertMate.showAlert(msg: "Failed to download Wine，\(error.localizedDescription)", type: .Error)
                            self.disableDownloadBtn = false
                            self.showWineDownloadBar = false
                            self.wineStatus = .nothing
                        }
                    }
                }
            },
            sendError: { msg in
                DispatchQueue.main.async {
                    self.alertMate.showAlert(msg: msg, type: .Error)
                    self.disableDownloadBtn = false
                    self.wineStatus = .nothing
                }
            }
        )
    }
    
    func checkWineStatus() {
        if WineManager.hasWineDownloaded() {
            if WineManager.hasWineInstalled() {
                wineStatus = .installed
            } else {
                wineStatus = .downloaded
                Task {
                    print("开始安装wine")
                    do {
                        try installWine()
                        DispatchQueue.main.async {
                            self.wineStatus = .installed
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.alertMate.showAlert(msg: error.localizedDescription, type: .Error)
                        }
                    }
                }
            }
        } else {
            wineStatus = .nothing
        }
    }
    
    func checkDllStatus() {
        if WineManager.hasReplaceDllFounded() {
            dllStatus = .downloaded
        } else {
            dllStatus = .nothing
        }
    }
    
    private func installWine() throws {
        try WineInstaller.installAndEnableWine(temp: LocalPaths.wineDir.appending(component: "wine.tar.gz"), wineDir: LocalPaths.wineDir)
    }
}
