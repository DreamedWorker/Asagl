//
//  AlertMate.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/1.
//

import Foundation

struct AlertMate {
    var showIt: Bool = false
    var msg: String = ""
    var title: String = ""
    var type: AlertType = .Info
    
    init(showIt: Bool = false, msg: String = "") {
        self.showIt = showIt
        self.msg = msg
    }
    
    mutating func showAlert(msg data: String, type: AlertType = .Info) {
        switch type {
        case .Info:
            title = NSLocalizedString("def.info", comment: "")
        case .Error:
            title = NSLocalizedString("def.warning", comment: "")
        }
        msg = data
        self.type = type
        showIt = true
    }
}

extension AlertMate {
    enum AlertType {
        case Info // 提示
        case Error // 警告
    }
}
