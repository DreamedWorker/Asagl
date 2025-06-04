//
//  Strings.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation

func formatBytes2ReadableString(bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    formatter.zeroPadsFractionDigits = true
    return formatter.string(fromByteCount: bytes)
}
