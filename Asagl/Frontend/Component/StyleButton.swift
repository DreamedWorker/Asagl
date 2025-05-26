//
//  StyleButton.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/5.
//

import SwiftUI

struct StyleButton: View {
    private let label: String
    private let action: () -> Void
    private let color: Bool
    
    init(label: String, action: @escaping () -> Void, color: Bool = false) {
        self.label = label
        self.action = action
        self.color = color
    }
    
    var body: some View {
        Button(
            action: action,
            label: { Text(NSLocalizedString(label, comment: "")).padding(.horizontal).padding(.vertical, 4) }
        )
        .buttonWithColor(color)
    }
}

struct ButtonColorModifier: ViewModifier {
    let useColor: Bool
    
    func body(content: Content) -> some View {
        if useColor {
            content.buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(.automatic)
        }
    }
}

extension View {
    func buttonWithColor(_ useColor: Bool) -> some View {
        self.modifier(ButtonColorModifier(useColor: useColor))
    }
}
