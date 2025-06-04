//
//  AsaglEndpoint.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation

class AsaglEndpoint {
    private static let session = URLSession(configuration: .ephemeral)
    
    /// 不带自定义请求头的GET
    static func simpleGET(url: String) async throws -> Data {
        let (data, _) = try await session.data(for: URLRequest(url: URL(string: url)!))
        return data
    }
}
