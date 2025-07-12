//
//  GameTimer.swift
//  Asagl
//
//  Created by 微晞鸢徊 on 2025/7/10.
//

import SwiftUI

struct GameTimer: View {
    @State private var hours = 0
    @State private var minutes = 0
    
    let gameType: GameType
    let typeDynamic: () -> GameType
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.title3)
                    .colorScheme(.dark)
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("home.gametime", comment: ""), String(hours), String(minutes)
                ))
                .font(.title3).colorScheme(.dark)
                .onAppear { readTimeFile(type: gameType) }
                .onChange(of: gameType, { _, newOne in readTimeFile(type: newOne) })
                .background(WindowFocusObserver(onFocus: {
                    readTimeFile(type: typeDynamic())
                }))
            }.padding()
        }
        .background(.thickMaterial.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .onTapGesture {
            readTimeFile(type: gameType)
        }
    }
    
    private func readTimeFile(type: GameType) {
        let timeFile = AppSettings.getPrefValue(key: "GameTime\(type.rawValue)", defVal: 0)
        let duration = TimeInterval(timeFile)
        let totalMinutes = Int(duration) / 60
        hours = totalMinutes / 60
        minutes = totalMinutes % 60
    }
}

fileprivate struct WindowFocusObserver: NSViewRepresentable {
    var onFocus: () -> Void
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { _ in
                    onFocus()
                }
            }
        }
        return view
    }
}
