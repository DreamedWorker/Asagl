//
//  AsaglApp.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/6/13.
//

import SwiftUI
import Sparkle

@main
struct AsaglApp: App {
    @NSApplicationDelegateAdaptor(AsaglAppDelegate.self) private var delegate
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            HomeScreen()
                .ignoresSafeArea()
                .frame(minWidth: 1280, idealWidth: 1280, maxWidth: 1280, minHeight: 720, idealHeight: 720, maxHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 720)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo, addition: {
                CheckForUpdatesView(updater: updaterController.updater)
            })
            CommandGroup(replacing: .newItem, addition: {})
        }
    }
}

class AsaglAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        LocalPaths.checkDirs()
        GameInstaller.makeDirs()
    }
}
