//
//  ContentView.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/6/4.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("firstOpenedVersion") private var lastVersion: String = ""
    @State private var showUpdateSheet = false
    
    var body: some View {
        HomeView()
            .onAppear {
                if lastVersion != "0.0.3" {
                    showUpdateSheet = true
                }
            }
            .onChange(of: lastVersion, { _, newOne in
                showUpdateSheet = newOne != "0.0.3"
            })
            .sheet(isPresented: $showUpdateSheet) {
                WizardScreen(refreshVersion: {
                    lastVersion = "0.0.3"
                })
                .interactiveDismissDisabled(true)
            }
    }
}

#Preview {
    ContentView()
}
