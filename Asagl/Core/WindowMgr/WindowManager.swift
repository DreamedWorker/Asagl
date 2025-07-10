//
//  WindowManager.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/10.
//

import Foundation
import SwiftUI

class WindowManager {
    static let shared = WindowManager()
    
    private var windows: [NSWindow] = []

    func openNewGameSettingsWindow(gameType: GameType) {
        let newView = GameSettingsWindow(gameType: gameType)
        let hostingController = NSHostingController(rootView: newView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        window.center()
        window.contentView = hostingController.view
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }
    
    func openAppSettingsWindow() {
        let newView = WineConfigView()
        let hostingController = NSHostingController(rootView: newView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        window.center()
        window.contentView = hostingController.view
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }
    
    func openEmergencyWindow() {
        let newView = EmergencyView()
        let hostingController = NSHostingController(rootView: newView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        window.center()
        window.contentView = hostingController.view
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }
}
