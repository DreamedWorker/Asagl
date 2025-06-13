//
//  ContentView.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(AppConfigKey.APP_FIRST_OPEN_VERSION) private var lastVersion: String = ""
    @State private var showUpdateSheet = false
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            if lastVersion != "1.0.0" {
                showUpdateSheet = true
            }
        }
        .onChange(of: lastVersion, { _, newOne in
            showUpdateSheet = newOne != "1.0.0"
        })
        .sheet(isPresented: $showUpdateSheet) {
            WizardView(
                refreshVersion: {
                    lastVersion = "1.0.0"
                }
            )
            .interactiveDismissDisabled(true)
        }
    }
}

#Preview {
    ContentView()
}
