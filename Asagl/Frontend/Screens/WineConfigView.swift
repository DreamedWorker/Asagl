//
//  WineConfigView.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/14.
//

import SwiftUI

struct WineConfigView: View {
    var body: some View {
        TabView {
            NormalWineConfig().tabItem {
                Label("settings.tab.wine", systemImage: "wineglass")
            }
            GameConfig().tabItem {
                Label("settings.tab.game", systemImage: "gamecontroller")
            }
            WineUpdateSwitcher().tabItem {
                Label("settings.tab.wineUpd", systemImage: "doc.badge.clock")
            }
        }
        .frame(width: 300)
    }
}

fileprivate struct GameConfig: View {
    @State private var localUsingAb: Bool = AppSettings.getPrefValue(key: AppConfigKey.USING_AB, defVal: false)
    
    var body: some View {
        HStack {
            Spacer()
            HStack {
                Spacer()
                Form {
                    Toggle("game.adv.fixup", isOn: $localUsingAb)
                        .onChange(of: localUsingAb) { _, new in
                            let old = AppSettings.getPrefValue(key: AppConfigKey.USING_AB, defVal: false)
                            if new != old {
                                AppSettings.setPrefValue(key: AppConfigKey.USING_AB, val: new)
                            }
                        }
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
}

fileprivate struct NormalWineConfig: View {
    @State private var localUsingMsync: Bool = AppSettings.getPrefValue(key: AppConfigKey.USING_MSYNC, defVal: true)
    @State private var localUsingHud: Bool = AppSettings.getPrefValue(key: AppConfigKey.USING_HUD, defVal: false)
    @State private var localUsingRetina: Bool = false;
    @State private var disableChanging: Bool = true
    @State private var alertMate = AlertMate()
    @State private var remoteRetinaState: Bool = false
    
    var body: some View {
        HStack {
            Spacer()
            HStack {
                Spacer()
                Form {
                    Toggle("game.adv.msync", isOn: $localUsingMsync)
                        .onChange(of: localUsingMsync) { _, new in
                            let old = AppSettings.getPrefValue(key: AppConfigKey.USING_MSYNC, defVal: true)
                            if new != old {
                                AppSettings.setPrefValue(key: AppConfigKey.USING_MSYNC, val: new)
                            }
                        }
                    Toggle("game.adv.retina", isOn: $localUsingRetina)
                        .disabled(disableChanging)
                        .onAppear { checkRetinaMode() }
                        .onChange(of: localUsingRetina) { _, new in
                            if new != remoteRetinaState {
                                disableChanging = true
                                Task.detached {
                                    if await new != remoteRetinaState {
                                        do {
                                            try WineRunner.changeRegValues(
                                                key: #"HKCU\Software\Wine\Mac Driver"#,
                                                name: "RetinaMode", data: new ? "y" : "n",
                                                type: .string
                                            )
                                            let isUsing = (try? WineRunner.isUsingRetinaMode()) ?? false
                                            await MainActor.run {
                                                remoteRetinaState = isUsing
                                                disableChanging = false
                                                if remoteRetinaState == new {
                                                    alertMate.showAlert(msg: NSLocalizedString("game.adv.retina.ok", comment: ""))
                                                }
                                            }
                                        } catch {
                                            await MainActor.run {
                                                alertMate.showAlert(
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
                    Toggle("game.adv.hud", isOn: $localUsingHud)
                        .onChange(of: localUsingHud) { _, new in
                            let old = AppSettings.getPrefValue(key: AppConfigKey.USING_HUD, defVal: false)
                            if new != old {
                                AppSettings.setPrefValue(key: AppConfigKey.USING_HUD, val: new)
                            }
                        }
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        .alert(alertMate.title, isPresented: $alertMate.showIt, actions: {}, message: { Text(alertMate.msg) })
    }
    
    private func checkRetinaMode() {
        disableChanging = true
        Task.detached {
            let isUsing = (try? WineRunner.isUsingRetinaMode()) ?? false
            await MainActor.run {
                remoteRetinaState = isUsing
                localUsingRetina = isUsing
                disableChanging = false
            }
        }
    }
}
