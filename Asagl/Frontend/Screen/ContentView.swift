//
//  ContentView.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/25.
//

import SwiftUI

struct ContentView: View {
    @State private var firstOpenedVersion = AppSettings.getPrefValue(key: AppConfigKey.APP_FIRST_OPEN_VERSION, defVal: "0.0.0")
    @State private var showWizard: Bool = false
    
    var body: some View {
        if firstOpenedVersion == "0.0.2" {
            HomeScreen()
        } else {
            ContentUnavailableView(
                "stage.ban.title",
                systemImage: "hand.raised.fill",
                description: Text("stage.ban.exp")
            )
            .onAppear { showWizard = true }
            .onTapGesture { showWizard = true }
            .sheet(isPresented: $showWizard, content: { WizardScreen(
                refreshVersion: {
                    showWizard = false
                    AppSettings.setPrefValue(key: AppConfigKey.APP_FIRST_OPEN_VERSION, val: "0.0.2")
                    firstOpenedVersion = AppSettings.getPrefValue(key: AppConfigKey.APP_FIRST_OPEN_VERSION, defVal: "0.0.0")
                },
                forceQuit: { showWizard = false }
            ) })
        }
    }
}

#Preview {
    ContentView()
}
