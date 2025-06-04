//
//  GameAdvancedSettingsPane.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/10.
//

import SwiftUI

struct GameAdvancedSettingsPane: View {
    @State private var localUsingMsync: Bool = AppSettings.getPrefValue(key: AppConfigKey.USING_MSYNC, defVal: true)
    @State private var localUsingHud: Bool = AppSettings.getPrefValue(key: AppConfigKey.USING_HUD, defVal: false)
    @State private var localUsingAb: Bool = AppSettings.getPrefValue(key: AppConfigKey.USING_AB, defVal: false)
    @State private var localUsingRetina: Bool = false; @State private var disableChanging: Bool = true
    @State private var alertMate = AlertMate()
    @State private var remoteRetinaState: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(
                isOn: $localUsingMsync,
                label: {
                    HStack {
                        Label("game.adv.msync", systemImage: "arrow.2.circlepath")
                        Spacer()
                    }
                }
            )
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: localUsingMsync) { _, new in
                let old = AppSettings.getPrefValue(key: AppConfigKey.USING_MSYNC, defVal: true)
                if new != old {
                    AppSettings.setPrefValue(key: AppConfigKey.USING_MSYNC, val: new)
                }
            }
            Text("game.adv.tip")
                .font(.footnote).foregroundStyle(.secondary)
                .padding(.bottom, 8)
            Toggle(
                isOn: $localUsingRetina,
                label: {
                    HStack {
                        Label("game.adv.retina", systemImage: "dot.scope.display")
                        Spacer()
                    }
                }
            )
            .disabled(disableChanging)
            .toggleStyle(.switch)
            .controlSize(.small)
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
            Text("game.adv.retina.tip")
                .font(.footnote).foregroundStyle(.secondary)
                .padding(.bottom, 8)
            Toggle(
                isOn: $localUsingHud,
                label: {
                    HStack {
                        Label("game.adv.hud", systemImage: "list.bullet.rectangle")
                        Spacer()
                    }
                }
            )
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: localUsingHud) { _, new in
                let old = AppSettings.getPrefValue(key: AppConfigKey.USING_HUD, defVal: false)
                if new != old {
                    AppSettings.setPrefValue(key: AppConfigKey.USING_HUD, val: new)
                }
            }
            Text("game.adv.hud.tip")
                .font(.footnote).foregroundStyle(.secondary)
                .padding(.bottom, 8)
            Toggle(
                isOn: $localUsingAb,
                label: {
                    HStack {
                        Label("game.adv.fixup", systemImage: "globe.badge.chevron.backward")
                        Spacer()
                    }
                }
            )
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: localUsingAb) { _, new in
                let old = AppSettings.getPrefValue(key: AppConfigKey.USING_AB, defVal: false)
                if new != old {
                    AppSettings.setPrefValue(key: AppConfigKey.USING_AB, val: new)
                }
            }
            Text("game.adv.fixup.tip")
                .font(.footnote).foregroundStyle(.secondary)
                .padding(.bottom, 16)
            HStack {
                Spacer()
                Text("game.adv.all").font(.footnote).foregroundStyle(.secondary)
            }
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
