//
//  AsaglApp.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/25.
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
            ContentView()
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
    func applicationWillFinishLaunching(_ notification: Notification) {
        Paths.checkDirs()
        Paths.checkBinaryFiles()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.collectionBehavior.remove(.fullScreenPrimary)
            window.standardWindowButton(.zoomButton)?.isEnabled = false
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

//@main
//struct AsaglApp: App {
//    @NSApplicationDelegateAdaptor(AsaglAppDelegate.self) private var delegate
//    @StateObject private var svm = SharedViewModel.shared
//    private let updaterController: SPUStandardUpdaterController
//    
//    init() {
//        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
//        // This is where you can also pass an updater delegate if you need one
//        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
//    }
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .alert(svm.alert.title, isPresented: $svm.alert.showIt, actions: {}, message: { Text(svm.alert.msg) })
//                .ignoresSafeArea()
//                .frame(minWidth: 1280, idealWidth: 1280, maxWidth: 1280, minHeight: 720, idealHeight: 720, maxHeight: 720)
//        }
//        .windowStyle(.hiddenTitleBar)
//        .defaultSize(width: 1280, height: 720)
//        .windowResizability(.contentSize)
//        .commands(content: {
//            CommandGroup(replacing: .newItem, addition: {})
//            CommandGroup(after: .appInfo) {
//                CheckForUpdatesView(updater: updaterController.updater)
//            }
//        })
//    }
//}
//
//class AsaglAppDelegate: NSObject, NSApplicationDelegate {
//    func applicationWillFinishLaunching(_ notification: Notification) {
//        Paths.checkDirs()
//        Paths.checkBinaryFiles()
//        Task {
//            let used = GlobalUsed.launcherBg
//            if used.shouldFetchToday {
//                _ = try? await used.fetchFromNetwork()
//                print("Fetched bg from network today")
//            } else {
//                print("Use cache info")
//            }
//        }
//    }
//    
//    func applicationDidFinishLaunching(_ notification: Notification) {
//    }
//    
//    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
//        return true
//    }
//}
