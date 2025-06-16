//
//  WineUpdateSwitcher.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/16.
//

import SwiftUI

struct WineUpdateSwitcher: View {
    @StateObject private var viewModel: WineUpdateViewModel = .init()
    @State private var versionTip: Bool = false
    
    var body: some View {
        HStack {
            Spacer()
            HStack {
                Spacer()
                Form {
                    Section("upd.wine.title") {
                        HStack {
                            Label(String.localizedStringWithFormat(
                                NSLocalizedString("upd.wine.version", comment: ""), viewModel.currentWineVersion
                            ),
                                  systemImage: "wineglass.fill"
                            )
                        }
                        .onAppear {
                            Task {
                                let version = viewModel.localWineVersion()
                                DispatchQueue.main.async {
                                    self.viewModel.currentWineVersion = version
                                }
                                await viewModel.fetchRemoteVersion()
                            }
                        }
                        if let selected = viewModel.selectedVersion {
                            VStack {
                                Picker(
                                    selection: Binding(
                                        get: { viewModel.selectedVersion ?? .init(version: "", title: "", url: "https://example.com") },
                                        set: { viewModel.selectedVersion = $0 }
                                    ),
                                    content: {
                                        ForEach(viewModel.remoteVersions, id: \.version) { ver in
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
                                        let oldVer = SemanticVersion(viewModel.currentWineVersion)
                                        let newVer = SemanticVersion(selected.version)
                                        if newVer < oldVer {
                                            versionTip = true
                                        } else {
                                            viewModel.doWineUpdate(version: selected)
                                        }
                                    })
                                }
                                if viewModel.showProgress {
                                    ProgressView(value: viewModel.downloadingProgress, total: 1)
                                    HStack {
                                        Text(
                                            String.localizedStringWithFormat(
                                                NSLocalizedString("wizard.download.progress", comment: ""),
                                                formatBytes2ReadableString(bytes: viewModel.completedBytes),
                                                formatBytes2ReadableString(bytes: viewModel.totalBytes)
                                            )
                                        ).font(.subheadline).monospacedDigit()
                                        Spacer()
                                    }.padding(.bottom)
                                }
                            }
                            .padding(.bottom)
                        }
                        HStack {
                            Spacer()
                            Button("game.upd.check", action: {
                                Task {
                                    await viewModel.fetchRemoteVersion()
                                }
                            })
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        .alert(
            "upd.wine.ver.title", isPresented: $versionTip,
            actions: {
                Button("def.cancel", role: .cancel, action: { versionTip = false })
                Button("def.confirm", role: .destructive, action: { viewModel.doWineUpdate(version: viewModel.selectedVersion!) })
            },
            message: { Text("upd.wine.ver.msg") }
        )
        .alert(viewModel.mate.title, isPresented: $viewModel.mate.showIt, actions: {}, message: { Text(viewModel.mate.msg) })
    }
    
    func formatBytes2ReadableString(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
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
                    if version.contains("10.9") {
                        try? "10.9.0".data(using: .utf8)!.write(to: versionFile)
                        return "10.9.0"
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
                            await MainActor.run {
                                self.showProgress = false
                                self.mate.showAlert(msg: NSLocalizedString("upd.wine.done", comment: ""))
                            }
                        } catch {
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
            )
        }
    }
}

fileprivate struct WineVersionElement: Codable, Hashable {
    let version, title: String
    let url: String
}

fileprivate typealias WineVersion = [WineVersionElement]
