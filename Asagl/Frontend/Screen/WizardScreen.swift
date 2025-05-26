//
//  WizardScreen.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import SwiftUI
import WineKit

struct WizardScreen: View {
    @State private var uiPart: WizardPart = .First
    
    let refreshVersion: () -> Void
    let forceQuit: () -> Void
    
    @ViewBuilder
    var body: some View {
        NavigationStack {
            switch uiPart {
            case .First:
                NavigationStack {
                    HStack {}.padding(.bottom, 16)
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
                    Link("wizard.importance.doc", destination: URL(string: "https://baidu.com")!)
                    StyleButton(
                        label: "wizard.start",
                        action: { uiPart = .Download },
                        color: true
                    ).padding(.bottom, 16)
                }
                .frame(width: 500, height: 400)
            case .Download:
                WizardDownloadScreen(
                    changeToNext: { uiPart = .Final },
                    forceQuit: { forceQuit() }
                )
                    .frame(width: 500, height: 400)
            case .Final:
                VStack {
                    Text("wizard.finish")
                    StyleButton(label: "wizard.entrance", action: { refreshVersion() }, color: true)
                }.onAppear { refreshVersion() }
                    .frame(width: 500, height: 400)
            }
        }
        .padding(20)
    }
    
    enum WizardPart {
        case First
        case Download
        case Final
    }
}

struct WizardDownloadScreen: View {
    @StateObject private var svm = SharedViewModel.shared
    @State private var downloadingProgress: Double = 0
    @State private var completedBytes: Int64 = 0
    @State private var totalBytes: Int64 = 0
    
    let changeToNext: () -> Void
    let forceQuit: () -> Void
    
    var body: some View {
        NavigationStack {
            HStack {}.padding(.bottom, 16)
            Text("wizard.download.title").font(.largeTitle).bold()
            Text("wizard.download.exp").foregroundStyle(.secondary)
            Spacer()
            ProgressView(value: downloadingProgress, total: 1)
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
            Image(systemName: "info.circle")
                .imageScale(.large)
                .foregroundStyle(.accent)
                .padding(.bottom, 4)
            Text("wizard.download.tip").font(.footnote).foregroundStyle(.secondary).padding(.bottom, 8)
        }
        .padding(20)
        .onAppear {
            Task.detached {
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
                if await hasWineConfigured() {
                    // 之前下载过 本次跳过 故也无需执行`installAndEnableWine`
                    // 更换新页面
                    await changeUI()
                } else {
//                    let wineURL = isInChina() ? "https://ghproxy.net/https://github.com/DreamedWorker/wine/releases/download/wine10.8/wine10.8.tar.gz"
//                    : "https://github.com/DreamedWorker/wine/releases/download/wine10.8/wine10.8.tar.gz"
                    let wineURL = "https://github.com/DreamedWorker/wine/releases/download/wine10.8/wine10.8.tar.gz"
                    downloadManager.startDownload(url: wineURL, finished: { temp in
                        Task.detached {
                            do {
                                // 解压并使Wine正常工作
                                try WineKit.installAndEnableWine(temp: temp, wineDir: Paths.wineDir)
                                // 更换新页面
                                await changeUI()
                            } catch {
                                await MainActor.run {
                                    forceQuit()
                                    svm.sendGlobalMessage(
                                        context: "无法下载Wine，\(error.localizedDescription)",
                                        msgType: .Error
                                    )
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    private func changeUI() async {
        await MainActor.run {
            changeToNext()
        }
    }
    
    // TODO: 鉴于新版本首次发布 如果此前参与过测试则先删除旧版的wine 此功能日后需还原为直接返回result的值
    private func hasWineConfigured() -> Bool {
        let result = FileManager.default.fileExists(atPath: Paths.wineDir.appending(component: "wine.tar.gz").toPath()) &&
        FileManager.default.fileExists(atPath: Paths.prefixDir.appending(component: "user.reg").toPath())
        if result {
            try! FileManager.default.removeItem(at: Paths.wineDir)
            try! FileManager.default.removeItem(at: Paths.prefixDir)
            try! FileManager.default.createDirectory(at: Paths.prefixDir, withIntermediateDirectories: true)
            try! FileManager.default.createDirectory(at: Paths.wineDir, withIntermediateDirectories: true)
        }
        return false
    }
}
