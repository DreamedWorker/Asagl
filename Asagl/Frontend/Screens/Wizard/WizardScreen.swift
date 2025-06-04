//
//  WizardScreen.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/6/4.
//

import SwiftUI

struct WizardScreen: View {
    @State private var uiPart: WizardPart = .First
    let refreshVersion: () -> Void
    
    @ViewBuilder
    var body: some View {
        switch uiPart {
        case .First:
            NavigationStack {
                Image("logo")
                    .resizable()
                    .imageScale(.large)
                    .frame(width: 92, height: 92)
                Text("wizard.title").font(.largeTitle).bold()
                Text("wizard.exp").foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "creditcard.trianglebadge.exclamationmark")
                    .imageScale(.large)
                    .foregroundStyle(.accent)
                Text("wizard.importance")
                    .font(.footnote).foregroundStyle(.secondary).padding(.bottom, 8)
                Link("wizard.importance.doc", destination: URL(string: "https://dreamedworker.github.io/Asagl/doc.html")!)
                StyleButton(
                    label: "wizard.start",
                    action: { uiPart = .Download },
                    color: true
                )
            }
            .padding()
            .frame(width: 500, height: 400)
        case .Download:
            WizardDownloadScreen(
                changeToNext: refreshVersion
            )
            .frame(width: 500, height: 400)
        }
    }
    
    enum WizardPart {
        case First
        case Download
    }
}

struct WizardDownloadScreen: View {
    @State private var useMirror: Bool = isInChina()
    @State private var downloadingProgress: Double = 0
    @State private var completedBytes: Int64 = 0
    @State private var totalBytes: Int64 = 0
    @State private var alertMate: AlertMate = .init()
    
    let changeToNext: () -> Void
    
    var body: some View {
        NavigationStack {
            Image(systemName: "square.and.arrow.down")
                .resizable()
                .foregroundStyle(.accent)
                .imageScale(.large)
                .frame(width: 92, height: 92)
            Text("wizard.download.title").font(.largeTitle).bold()
            Text("wizard.download.exp").foregroundStyle(.secondary)
            Spacer()
            ProgressView(value: downloadingProgress, total: 1)
            HStack {
                Spacer()
                Toggle(isOn: $useMirror, label: { Label("wizard.download.mirror", systemImage: "network") })
                    .toggleStyle(.switch).controlSize(.small)
            }
            HStack {
                Text(
                    String.localizedStringWithFormat(
                        NSLocalizedString("wizard.download.progress", comment: ""),
                        formatBytes2ReadableString(bytes: completedBytes),
                        formatBytes2ReadableString(bytes: totalBytes)
                    )
                ).font(.callout).monospacedDigit()
                Spacer()
            }
            Spacer()
            StyleButton(label: "wizard.start", action: {
                Task {
                    if hasWineConfigured() {
                        await changeUI()
                    } else {
                        let downloadManager = DownloadManager(
                            process: { process, cur, tot in
                                Task {
                                    await MainActor.run {
                                        if 0.0...1.0 ~= process {
                                            downloadingProgress = process
                                        }
                                        completedBytes = cur
                                        totalBytes = tot
                                    }
                                }
                            }
                        )
                        let wineURL = useMirror ?
                        "https://ghproxy.net/https://github.com/DreamedWorker/wine/releases/download/wine10.8/wine10.8.tar.gz"
                        : "https://github.com/DreamedWorker/wine/releases/download/wine10.8/wine10.8.tar.gz"
                        downloadManager.startDownload(url: wineURL) { temp in
                            Task {
                                do {
                                    try WineInstall.installAndEnableWine(temp: temp, wineDir: Paths.wineDir)
                                    await changeUI()
                                } catch {
                                    await MainActor.run {
                                        alertMate.showAlert(msg: "Failed to download Wine，\(error.localizedDescription)", type: .Error)
                                    }
                                }
                            }
                        }
                    }
                }
            }, color: true)
            Image(systemName: "info.circle")
                .imageScale(.large)
                .foregroundStyle(.accent)
                .padding(.bottom, 4)
            Text("wizard.download.tip").font(.footnote).foregroundStyle(.secondary).padding(.bottom, 8)
        }
        .padding()
        .alert(alertMate.msg, isPresented: $alertMate.showIt, actions: {
            Button("def.confirm", action: {
                NSApplication.shared.terminate(self)
            })
        })
    }
    
    private func changeUI() async {
        await MainActor.run {
            changeToNext()
        }
    }
    
    private func hasWineConfigured() -> Bool {
        let result = FileManager.default.fileExists(atPath: Paths.wineDir.appending(component: "wine.tar.gz").toPath()) &&
        FileManager.default.fileExists(atPath: Paths.prefixDir.appending(component: "user.reg").toPath())
        return result
    }
}
