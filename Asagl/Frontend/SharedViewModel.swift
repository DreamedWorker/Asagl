//
//  SharedViewModel.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation

class SharedViewModel : ObservableObject {
    static let shared = SharedViewModel()
    @Published var alert = AlertMate()
    
    /// 基于在WindowGroup的锚点 向全局发送弹窗式通知
    func sendGlobalMessage(context: String, msgType: AlertMate.AlertType) {
        alert.showAlert(msg: context, type: msgType)
    }
}
