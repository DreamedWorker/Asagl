//
//  URL+Extension.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation

extension URL {
    func toPath() -> String {
        return self.path(percentEncoded: false)
    }
}
