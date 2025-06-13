//
//  WizardView.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import SwiftUI

fileprivate enum WizardScreens {
    case hello
    case downloadWine
}

struct WizardView: View {
    @State private var screen: WizardScreens = .hello
    let refreshVersion: () -> Void
    
    @ViewBuilder
    var body: some View {
        switch screen {
        case .hello:
            WizardHello(nextPage: {
                withAnimation {
                    screen = .downloadWine
                }
            })
        case .downloadWine:
            WizardDownloadWine(changeToNext: refreshVersion)
        }
    }
}

fileprivate struct WizardDownloadWine: View {
    @State private var useMirror: Bool = Locale.autoupdatingCurrent.identifier.contains("CN")
    @State private var downloadingProgress: Double = 0
    @State private var completedBytes: Int64 = 0
    @State private var totalBytes: Int64 = 0
    @State private var disableDownloadBtn = false
    @State private var alertMate: AlertMate = .init()
    
    let changeToNext: () -> Void
    
    func formatBytes2ReadableString(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 90))
                    .foregroundStyle(.accent)
                Text("wizard.download.title").font(.largeTitle).bold()
                Text("wizard.download.exp").foregroundStyle(.secondary).padding(.bottom)
                Spacer()
                HStack {
                    Toggle(isOn: $useMirror, label: { Label("wizard.download.mirror", systemImage: "network") })
                    Spacer()
                }
                ProgressView(value: downloadingProgress, total: 1)
                HStack {
                    Text(
                        String.localizedStringWithFormat(
                            NSLocalizedString("wizard.download.progress", comment: ""),
                            formatBytes2ReadableString(bytes: completedBytes),
                            formatBytes2ReadableString(bytes: totalBytes)
                        )
                    ).font(.subheadline).monospacedDigit()
                    Spacer()
                }.padding(.bottom)
                Spacer()
                Button("wizard.start", action: {
                    Task {
                        if !hasWineConfigured() {
                            disableDownloadBtn = true
                            let wineURL = useMirror ?
                            "https://ghproxy.net/https://github.com/DreamedWorker/wine/releases/download/wine10.9/wine10.9.tar.gz"
                            : "https://github.com/DreamedWorker/wine/releases/download/wine10.9/wine10.9.tar.gz"
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
                            downloadManager.startDownload(
                                url: wineURL,
                                finished: { temp in
                                    Task {
                                        do {
                                            try WineInstaller.installAndEnableWine(temp: temp, wineDir: LocalPaths.wineDir)
                                            await changeUI()
                                        } catch {
                                            await MainActor.run {
                                                alertMate.showAlert(msg: "Failed to download Wine，\(error.localizedDescription)", type: .Error)
                                                disableDownloadBtn = false
                                            }
                                        }
                                    }
                                },
                                sendError: { msg in
                                    DispatchQueue.main.async {
                                        self.alertMate.showAlert(msg: msg, type: .Error)
                                        disableDownloadBtn = false
                                    }
                                }
                            )
                        } else {
                            await changeUI()
                        }
                    }
                })
                .disabled(disableDownloadBtn)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .background(.regularMaterial)
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
        let result = FileManager.default.fileExists(atPath: LocalPaths.wineDir.appending(component: "wine.tar.gz").toPath()) &&
        FileManager.default.fileExists(atPath: LocalPaths.prefixDir.appending(component: "user.reg").toPath())
        return result
    }
}

fileprivate struct WizardHello: View {
    let nextPage: () -> Void
    
    var body: some View {
        NavigationStack {
            Image("logo")
                .resizable()
                .imageScale(.large)
                .frame(width: 92, height: 92)
            Text("wizard.title").font(.largeTitle).bold()
            Text("wizard.exp").foregroundStyle(.secondary).padding(.bottom)
            Button(
                action: { NSWorkspace.shared.open(URL(string: "https://dreamedworker.github.io/Asagl/doc.html")!) },
                label: {
                    FeatureTile(iconName: "doc.text", descriptionKey: "wizard.importance.doc")
                }
            ).buttonStyle(.borderless)
            Spacer()
            Button(action: nextPage, label: { Text("wizard.start").padding() })
                .buttonStyle(.borderedProminent)
                .padding(.vertical)
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .imageScale(.large)
                .foregroundStyle(.accent)
            Text("wizard.importance")
                .font(.footnote).foregroundStyle(.secondary).padding(.bottom, 8)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .background(.regularMaterial)
    }
}
