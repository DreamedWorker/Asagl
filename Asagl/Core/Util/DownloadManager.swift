//
//  DownloadManager.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/8.
//

import Foundation

class DownloadManager {
    private lazy var session = URLSession(configuration: .ephemeral)
    private var downloadTask: URLSessionDownloadTask? = nil
    private var observation: NSKeyValueObservation? = nil
    
    let process: (Double, Int64, Int64) -> Void
    
    init(process: @escaping (Double, Int64, Int64) -> Void) {
        self.process = process
    }
    
    func startDownload(
        url: String,
        finished: @escaping (URL) -> Void,
        sendError: @escaping (String) -> Void
    ) {
        downloadTask = session.downloadTask(with: URL(string: url)!) { objectURL, _, error in
            if let error = error {
                sendError(error.localizedDescription)
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                if let confirmedURL = objectURL {
                    finished(confirmedURL)
                }
            }
        }
        observation = downloadTask?.observe(\.countOfBytesReceived) { task, _ in
            DispatchQueue.main.async {
                let totalBytes = task.countOfBytesExpectedToReceive
                let completedBytes = task.countOfBytesReceived
                let fractionProgress = Double(completedBytes) / Double(totalBytes)
                self.process(fractionProgress, completedBytes, totalBytes)
            }
        }
        downloadTask?.resume()
    }
}
