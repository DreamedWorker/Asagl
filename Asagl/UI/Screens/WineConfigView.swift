//
//  WineConfigView.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/14.
//

import SwiftUI

struct WineConfigView: View {
    @StateObject private var normalSettings = NormalWineConfigViewModel()
    @StateObject private var wineSettings = WineUpdateViewModel()
    @State private var versionTip: Bool = false
    
    var body: some View {
        Form {
            Section("settings.tab.wine") {
                Toggle("game.adv.msync", isOn: $normalSettings.localUsingMsync)
                    .onChange(of: normalSettings.localUsingMsync) { _, new in
                        let old = AppSettings.getPrefValue(key: AppConfigKey.USING_MSYNC, defVal: true)
                        if new != old {
                            AppSettings.setPrefValue(key: AppConfigKey.USING_MSYNC, val: new)
                        }
                    }
                Toggle("game.adv.retina", isOn: $normalSettings.localUsingRetina)
                    .disabled(normalSettings.disableChanging)
                    .onAppear { normalSettings.checkRetinaMode() }
                    .onChange(of: normalSettings.localUsingRetina) { _, new in
                        if new != normalSettings.remoteRetinaState {
                            normalSettings.disableChanging = true
                            Task.detached {
                                if await new != normalSettings.remoteRetinaState {
                                    do {
                                        try WineRunner.changeRegValues(
                                            key: #"HKCU\Software\Wine\Mac Driver"#,
                                            name: "RetinaMode", data: new ? "y" : "n",
                                            type: .string
                                        )
                                        let isUsing = (try? WineRunner.isUsingRetinaMode()) ?? false
                                        await MainActor.run {
                                            normalSettings.remoteRetinaState = isUsing
                                            normalSettings.disableChanging = false
                                            if normalSettings.remoteRetinaState == new {
                                                normalSettings.alertMate.showAlert(msg: NSLocalizedString("game.adv.retina.ok", comment: ""))
                                            }
                                        }
                                    } catch {
                                        await MainActor.run {
                                            normalSettings.alertMate.showAlert(
                                                msg: String.localizedStringWithFormat(
                                                    NSLocalizedString("game.adv.retina.failed", comment: ""),
                                                    error.localizedDescription
                                                ),
                                                type: .Error
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                Toggle("game.adv.hud", isOn: $normalSettings.localUsingHud)
                    .onChange(of: normalSettings.localUsingHud) { _, new in
                        let old = AppSettings.getPrefValue(key: AppConfigKey.USING_HUD, defVal: false)
                        if new != old {
                            AppSettings.setPrefValue(key: AppConfigKey.USING_HUD, val: new)
                        }
                    }
            }
            Section("settings.tab.game") {
                Toggle("game.adv.fixup", isOn: $normalSettings.localUsingAb)
                    .onChange(of: normalSettings.localUsingAb) { _, new in
                        let old = AppSettings.getPrefValue(key: AppConfigKey.USING_AB, defVal: false)
                        if new != old {
                            AppSettings.setPrefValue(key: AppConfigKey.USING_AB, val: new)
                        }
                    }
                HStack {
                    Text("game.adv.uesDll")
                    Spacer()
                    Button("game.adv.useDll.backup", action: {
                        Task {
                            do {
                                try GameSettings.backupDlls()
                                DispatchQueue.main.async {
                                    self.normalSettings.alertMate.showAlert(msg: NSLocalizedString("game.adv.info.backupDll", comment: ""))
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.normalSettings.alertMate.showAlert(msg: NSLocalizedString("game.adv.error.backupDll", comment: ""))
                                }
                            }
                        }
                    })
                    Button("game.adv.uesDll.apply", action: {
                        Task {
                            do {
                                if WineManager.hasReplaceDllFounded() {
                                    try GameSettings.replaceDll()
                                    DispatchQueue.main.async {
                                        self.normalSettings.alertMate.showAlert(
                                            msg: NSLocalizedString("game.adv.info.replaceDll", comment: "")
                                        )
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.normalSettings.alertMate.showAlert(
                                            msg: NSLocalizedString("game.adv.error.applyLackFile", comment: "")
                                        )
                                    }
                                }
                            } catch {
                                do {
                                    try GameSettings.dllRollback()
                                    DispatchQueue.main.async {
                                        self.normalSettings.alertMate.showAlert(
                                            msg: NSLocalizedString("game.adv.error.replaceDllRepaired", comment: "")
                                        )
                                    }
                                } catch {
                                    DispatchQueue.main.async {
                                        self.normalSettings.alertMate.showAlert(
                                            msg: NSLocalizedString("game.adv.error.replaceDll", comment: "")
                                        )
                                    }
                                }
                            }
                        }
                    })
                    Button("game.adv.uesDll.rollback", action: {
                        Task {
                            do {
                                try GameSettings.dllRollback()
                                DispatchQueue.main.async {
                                    self.normalSettings.alertMate.showAlert(
                                        msg: NSLocalizedString("game.adv.info.rollbackDll", comment: "")
                                    )
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.normalSettings.alertMate.showAlert(
                                        msg: String.localizedStringWithFormat(NSLocalizedString("game.adv.error.rollbackDll", comment: ""), error.localizedDescription)
                                    )
                                }
                            }
                        }
                    })
                }
            }
            Section("settings.tab.wineUpd") {
                HStack {
                    Label("upd.wine.version", systemImage: "wineglass.fill")
                    Spacer()
                    Text(wineSettings.currentWineVersion).foregroundStyle(.secondary)
                }
                .onAppear {
                    Task {
                        let version = wineSettings.localWineVersion()
                        DispatchQueue.main.async {
                            self.wineSettings.currentWineVersion = version
                        }
                        await wineSettings.fetchRemoteVersion()
                    }
                }
                if let selected = wineSettings.selectedVersion {
                    if wineSettings.showProgress {
                        VStack {
                            ProgressView(value: wineSettings.downloadingProgress, total: 1)
                            HStack {
                                Text(
                                    String.localizedStringWithFormat(
                                        NSLocalizedString("wizard.download.progress", comment: ""),
                                        formatBytes2ReadableString(bytes: wineSettings.completedBytes),
                                        formatBytes2ReadableString(bytes: wineSettings.totalBytes)
                                    )
                                ).font(.subheadline).monospacedDigit()
                                Spacer()
                            }.padding(.bottom)
                        }
                    }
                    VStack {
                        Picker(
                            selection: Binding(
                                get: { wineSettings.selectedVersion ?? .init(version: "", title: "", url: "https://example.com") },
                                set: { wineSettings.selectedVersion = $0 }
                            ),
                            content: {
                                ForEach(wineSettings.remoteVersions, id: \.version) { ver in
                                    Text(ver.title).tag(ver)
                                }
                            },
                            label: {
                                Text("upd.wine.remoteVersions")
                            }
                        )
                        HStack {
                            Spacer()
                            Button("upd.wine.applyUpd", action: {
                                let oldVer = SemanticVersion(wineSettings.currentWineVersion)
                                let newVer = SemanticVersion(selected.version)
                                if newVer < oldVer {
                                    versionTip = true
                                } else {
                                    wineSettings.doWineUpdate(version: selected)
                                }
                            })
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert(
            normalSettings.alertMate.title,
            isPresented: $normalSettings.alertMate.showIt, actions: {},
            message: { Text(normalSettings.alertMate.msg) }
        )
        .alert(
            "upd.wine.ver.title", isPresented: $versionTip,
            actions: {
                Button("def.cancel", role: .cancel, action: { versionTip = false })
                Button("def.confirm", role: .destructive, action: { wineSettings.doWineUpdate(version: wineSettings.selectedVersion!) })
            },
            message: { Text("upd.wine.ver.msg") }
        )
        .navigationTitle(Text("home.side.settings"))
    }
    
    func formatBytes2ReadableString(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
    }
}

fileprivate class NormalWineConfigViewModel: ObservableObject {
    @Published var localUsingMsync: Bool = AppSettings.getPrefValue(key: AppConfigKey.USING_MSYNC, defVal: true)
    @Published var localUsingHud: Bool = AppSettings.getPrefValue(key: AppConfigKey.USING_HUD, defVal: false)
    @Published var localUsingAb: Bool = AppSettings.getPrefValue(key: AppConfigKey.USING_AB, defVal: false)
    @Published var localUsingRetina: Bool = false;
    @Published var disableChanging: Bool = true
    @Published var alertMate = AlertMate()
    @Published var remoteRetinaState: Bool = false
    
    func checkRetinaMode() {
        disableChanging = true
        Task.detached {
            let isUsing = (try? WineRunner.isUsingRetinaMode()) ?? false
            await MainActor.run {
                self.remoteRetinaState = isUsing
                self.localUsingRetina = isUsing
                self.disableChanging = false
            }
        }
    }
}

fileprivate class WineUpdateViewModel: ObservableObject {
    @Published var remoteVersions: WineVersion = []
    @Published var selectedVersion: WineVersionElement? = nil
    @Published var mate: AlertMate = .init()
    @Published var currentWineVersion: String = NSLocalizedString("upd.wine.verIng", comment: "")
    @Published var downloadingProgress: Double = 0
    @Published var completedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var showProgress: Bool = false
    
    func localWineVersion() -> String {
        let versionFile = LocalPaths.wineDir.appending(component: "version.txt")
        if FileManager.default.fileExists(atPath: versionFile.toPath()) {
            return try! String(contentsOf: versionFile, encoding: .utf8)
        } else {
            do {
                let versionOri = try WineRunner.runWineCmd(args: ["--version"])
                if versionOri.retCode == 0 {
                    let version = String(versionOri.outputData.split(separator: "-").last!)
                    if version.contains("10.10") {
                        try? "10.10.0".data(using: .utf8)!.write(to: versionFile)
                        return "10.10.0"
                    } else {
                        try? version.data(using: .utf8)!.write(to: versionFile)
                        return version
                    }
                } else {
                    return "unknown"
                }
            } catch {
                return "unknown"
            }
        }
    }
    
    func fetchRemoteVersion() async {
        let versionURL = "https://dreamedworker.github.io/Asagl/wine_version.json"
        do {
            let formatted = try await JSONDecoder().decode(WineVersion.self, from: AsaglEndpoint.simpleGET(url: versionURL))
            await MainActor.run {
                remoteVersions = formatted
                if remoteVersions.contains(where: { $0.version == currentWineVersion }) {
                    let index = remoteVersions.firstIndex(where: { $0.version == currentWineVersion })!
                    selectedVersion = remoteVersions[index]
                } else {
                    selectedVersion = remoteVersions.first!
                }
            }
        } catch {
            print(error)
            await MainActor.run {
                mate.showAlert(msg: error.localizedDescription, type: .Error)
            }
        }
    }
    
    func doWineUpdate(version: WineVersionElement) {
        showProgress = true
        Task {
            do {
                try WineInstaller.backupOriginalPrefix()
                try FileManager.default.removeItem(at: LocalPaths.prefixDir)
                try FileManager.default.createDirectory(at: LocalPaths.prefixDir, withIntermediateDirectories: true)
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
                    url: version.url,
                    finished: { temp in
                        Task {
                            do {
                                let oldWineRoot = LocalPaths.wineDir.appending(component: "wine")
                                let oldWineTar = LocalPaths.wineDir.appending(component: "wine.tar.gz")
                                if FileManager.default.fileExists(atPath: oldWineRoot.toPath()) {
                                    try! FileManager.default.removeItem(at: oldWineRoot)
                                }
                                try WineInstaller.installAndEnableWine(temp: temp, wineDir: LocalPaths.wineDir, wineTarName: "wine-temp.tar.gz")
                                if FileManager.default.fileExists(atPath: oldWineTar.toPath()) {
                                    try! FileManager.default.removeItem(at: oldWineTar)
                                }
                                try FileManager.default.moveItem(at: LocalPaths.wineDir.appending(component: "wine-temp.tar.gz"), to: oldWineTar)
                                let versionFile = LocalPaths.wineDir.appending(component: "version.txt")
                                try version.version.data(using: .utf8)!.write(to: versionFile)
                                try? FileManager.default.removeItem(at: LocalPaths.resourceDir.appending(component: "WinePrefixBak"))
                                await MainActor.run {
                                    self.showProgress = false
                                    self.mate.showAlert(msg: NSLocalizedString("upd.wine.done", comment: ""))
                                }
                            } catch {
                                if FileManager.default.fileExists(atPath: LocalPaths.prefixDir.toPath()) {
                                    try! FileManager.default.removeItem(at: LocalPaths.prefixDir)
                                    try! FileManager.default.moveItem(
                                        at: LocalPaths.resourceDir.appending(component: "WinePrefixBak"),
                                        to: LocalPaths.prefixDir
                                    )
                                }
                                await MainActor.run {
                                    self.showProgress = false
                                    self.mate.showAlert(
                                        msg: String.localizedStringWithFormat(
                                            NSLocalizedString("upd.wine.failed", comment: ""), error.localizedDescription
                                        ),
                                        type: .Error
                                    )
                                }
                            }
                        }
                    },
                    sendError: { msg in
                        Task {
                            if FileManager.default.fileExists(atPath: LocalPaths.prefixDir.toPath()) {
                                try! FileManager.default.removeItem(at: LocalPaths.prefixDir)
                                try! FileManager.default.moveItem(
                                    at: LocalPaths.resourceDir.appending(component: "WinePrefixBak"),
                                    to: LocalPaths.prefixDir
                                )
                            }
                            DispatchQueue.main.async {
                                self.showProgress = false
                                self.mate.showAlert(
                                    msg: String.localizedStringWithFormat(
                                        NSLocalizedString("upd.wine.failed", comment: ""), msg
                                    ),
                                    type: .Error
                                )
                            }
                        }
                    }
                )
            } catch {
                DispatchQueue.main.async {
                    self.mate.showAlert(msg: "upd.wine.fatalError", type: .Error)
                }
            }
        }
    }
}

fileprivate struct WineVersionElement: Codable, Hashable {
    let version, title: String
    let url: String
}

fileprivate typealias WineVersion = [WineVersionElement]
