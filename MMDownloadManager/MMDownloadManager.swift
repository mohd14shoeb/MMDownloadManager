//
//  MMDownloadManager.swift
//  MeMe
//
//  Created by zhang yinglong on 2017/6/21.
//  Copyright © 2017年 sip. All rights reserved.
//

import Foundation

public enum MMWaitingQueueMode: Int {
    case fifo // 先进先出
    case filo // 先进后出
}

public class MMDownloadManager: NSObject {
    
    private static let shared = MMDownloadManager()
    
    open class var `default`: MMDownloadManager { get { return shared } }
    
    fileprivate let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    
    open var saveFilesDirectory: String = "download" {
        didSet {
            let dir = cachesDirectory.appendingPathComponent(saveFilesDirectory).path
            if !FileManager.default.fileExists(atPath: dir) {
                do {
                    try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    fileprivate var filesTotalLengthPlistPath: String {
        get {
            return cachesDirectory.appendingPathComponent(saveFilesDirectory)
                .appendingPathComponent("filesTotalLength.plist").path
        }
    }
    
    open var maxConcurrentCount = -1
    
    open var waitingQueueMode: MMWaitingQueueMode = .fifo
    
    fileprivate var urlSession: URLSession {
        get {
            return URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue())
        }
    }
    
    fileprivate var downloadModelsDic = [String: MMDownloadModel]()
    fileprivate var downloadingModels = [MMDownloadModel]()
    fileprivate var waitingModels = [MMDownloadModel]()
    
    override init() {
        let dir = cachesDirectory.appendingPathComponent(saveFilesDirectory).path
        if !FileManager.default.fileExists(atPath: dir) {
            do {
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
}

extension MMDownloadManager: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        guard let taskDescription = dataTask.taskDescription else { return }
        guard let downloadModel = downloadModelsDic[taskDescription] else { return }
        guard let url = downloadModel.url else { return }
        
        downloadModel.openOutputStream()
        let totalLength = response.expectedContentLength + hasDownloadedLength(url)
        downloadModel.totalLength = totalLength
        
        let filesTotalLength: NSMutableDictionary = NSMutableDictionary(contentsOfFile: filesTotalLengthPlistPath) ?? NSMutableDictionary(capacity: 1)
        filesTotalLength[url.lastPathComponent] = totalLength
        filesTotalLength.write(toFile: filesTotalLengthPlistPath, atomically: true)

        completionHandler(.allow)
    }
    
//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
//        guard let taskDescription = dataTask.taskDescription else { return }
//        guard let downloadModel = downloadModelsDic[taskDescription] else { return }
//        guard let url = downloadModel.url else { return }
//    }
//
//
//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
//        guard let taskDescription = dataTask.taskDescription else { return }
//        guard let downloadModel = downloadModelsDic[taskDescription] else { return }
//        guard let url = downloadModel.url else { return }
//
//    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let taskDescription = dataTask.taskDescription else { return }
        guard let downloadModel = downloadModelsDic[taskDescription] else { return }
        guard let url = downloadModel.url else { return }
        guard let outputStream = downloadModel.outputStream else { return }
        
        outputStream.write(data.bytes, maxLength: data.count)
        
        let receivedSize = hasDownloadedLength(url)
        let expectedSize = downloadModel.totalLength
        if expectedSize == 0 {
            return
        }
        
        main_async {
            downloadModel.progressClosure?(receivedSize, expectedSize, 1.0 * Float(receivedSize) / Float(expectedSize))
        }
    }
    
//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Swift.Void) {
//        guard let taskDescription = dataTask.taskDescription else { return }
//        guard let downloadModel = downloadModelsDic[taskDescription] else { return }
//        guard let url = downloadModel.url else { return }
//    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // cancel task
        if let err = error as NSError?, err.code == -999 { return }
        
        guard let taskDescription = task.taskDescription else { return }
        guard let downloadModel = downloadModelsDic[taskDescription] else { return }
        guard let url = downloadModel.url else { return }
        
        downloadModel.closeOutputStream()
        downloadModelsDic.removeValue(forKey: taskDescription)
        _ = downloadingModels.remove(of: downloadModel)
        
        main_async { [weak self] in
            guard let weakSelf = self else { return }
            
            if weakSelf.isDownloadCompletedOfURL(url) {
                let fullPath = self?.fileFullPathOfURL(url)
                let destPath = downloadModel.destPath
                if (destPath != nil) {
                    do {
                        try FileManager.default.moveItem(atPath: fullPath!, toPath: destPath!)
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
                downloadModel.stateClosure?(.completed)
                downloadModel.completionClosure?(true, (destPath ??  fullPath), nil)
            } else {
                downloadModel.stateClosure?(.failed)
                downloadModel.completionClosure?(false, nil, error)
            }
        }
        
        resumeNextDowloadModel()
    }
    
}

extension MMDownloadManager {
    
    public func fileFullPathOfURL(_ url: URL) -> String {
        return cachesDirectory.appendingPathComponent(saveFilesDirectory)
            .appendingPathComponent(url.lastPathComponent).path
    }
    
    public func fileHasDownloadedProgressOfURL(_ url: URL) -> Float {
        if  isDownloadCompletedOfURL(url) {
            return 1.0
        }
        
        if totalLength(url) == 0 {
            return 0.0
        }
        
        return 1.0 * Float(hasDownloadedLength(url)) / Float(totalLength(url))
    }
    
    public func isDownloadCompletedOfURL(_ url: URL) -> Bool {
        let total = totalLength(url)
        if total > 0 {
            if total == hasDownloadedLength(url) {
                return true
            }
        }
        return false
    }
    
    public func canResumeDownload() -> Bool {
        if maxConcurrentCount == -1 {
            return true
        }
        
        if downloadingModels.count >= maxConcurrentCount {
            return false
        }
        
        return true
    }
    
    fileprivate func totalLength(_ url: URL) -> Int64 {
        guard let filesTotalLength = NSDictionary(contentsOfFile: filesTotalLengthPlistPath) else {
            return 0
        }
        
        guard let size = filesTotalLength[url.lastPathComponent] else {
            return 0
        }
        
        return (size as! NSNumber).int64Value
    }
    
    public func hasDownloadedLength(_ url: URL) -> Int64 {
        var length: Int64 = 0
        let fullPath = fileFullPathOfURL(url)
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fullPath)
            if let size = fileAttributes[FileAttributeKey.size] {
                length = (size as! NSNumber).int64Value
            }
        } catch let error {
            print(error.localizedDescription)
        }
        return length
    }
    
    fileprivate func resumeNextDowloadModel() {
        guard maxConcurrentCount != -1 else { return } // 无限制同时下载个数
        guard waitingModels.count > 0 else { return } // 等待队列中有任务
        
        var downloadModel: MMDownloadModel
        switch waitingQueueMode {
        case .fifo:
            downloadModel = waitingModels.first!
        case .filo:
            downloadModel = waitingModels.last!
        }
        _ = waitingModels.remove(of: downloadModel)
        
        var downloadState: MMDownloadState = .waiting
        if canResumeDownload() {
            downloadingModels.append(downloadModel)
            downloadModel.dataTask?.resume()
            downloadState = .running
        } else {
            waitingModels.append(downloadModel)
            downloadState = .waiting
        }
        
        main_async {
            downloadModel.stateClosure?(downloadState)
        }
    }
}

// MARK-- user interface
extension MMDownloadManager {
    
    /**
     Starts a file download action with URL, download state, download progress and download completion block.
     
     @param url        The URL of the file which to be downloaded.
     @param destPath   The path to save the file after the download is completed, if pass nil file will be saved in default path.
     @param state      A block object to be executed when the download state changed.
     @param progress   A block object to be executed when the download progress changed.
     @param completion A block object to be executed when the download completion.
     */
    public func downloadURL(_ url: URL, destPath: String? = nil, state: StateClosure? = nil, progress: ProgressClosure? = nil, completion: CompletionClosure? = nil) {
        
        guard downloadModelsDic[url.lastPathComponent] == nil else { return } // 已存在的下载
        
        if isDownloadCompletedOfURL(url) { // 已完成的下载
            state?(.completed)
            completion?(true, fileFullPathOfURL(url), nil)
            return
        }
        
        print("beging downloadURL = \(url)")
        var request = URLRequest(url: url)
        request.setValue(String(format: "bytes=%ld-", hasDownloadedLength(url)), forHTTPHeaderField: "Range")
        let dataTask = urlSession.dataTask(with: request)
        dataTask.taskDescription = url.lastPathComponent
        
        let downloadModel = MMDownloadModel()
        downloadModel.url = url
        downloadModel.dataTask = dataTask
        downloadModel.outputStream = OutputStream(toFileAtPath: fileFullPathOfURL(url), append: true)
        downloadModel.destPath = destPath
        downloadModel.stateClosure = state
        downloadModel.progressClosure = progress
        downloadModel.completionClosure = completion
        downloadModelsDic[url.lastPathComponent] = downloadModel
        
        var downloadState: MMDownloadState = .waiting
        if canResumeDownload() {
            downloadingModels.append(downloadModel)
            dataTask.resume()
            downloadState = .running
        } else {
            waitingModels.append(downloadModel)
            downloadState = .waiting
        }
        
        main_async {
            downloadModel.stateClosure?(downloadState)
        }
        
    }
    
    /**
     Suspend a file download action with URL.
     
     @param url        The URL of the file which to be suspended.
     */
    public func suspendDownloadOfURL(_ url: URL) {
        guard let downloadModel = downloadModelsDic[url.lastPathComponent] else { return }
        
        main_async {
            downloadModel.stateClosure?(.suspended)
        }
        
        if waitingModels.contains(downloadModel) {
           _ = waitingModels.remove(of: downloadModel)
        } else {
            downloadModel.dataTask?.suspend()
            _ = downloadingModels.remove(of: downloadModel)
        }
        
        resumeNextDowloadModel()
    }
    
    /**
     Suspend all files download action.
     */
    public func suspendAllDownloads() {
        if downloadModelsDic.count == 0 { return }
        
        if waitingModels.count > 0 {
            waitingModels.forEach({ downloadModel in
                main_async {
                    downloadModel.stateClosure?(.suspended)
                }
            })
            waitingModels.removeAll()
        }
        
        if downloadingModels.count > 0 {
            downloadingModels.forEach({ downloadModel in
                downloadModel.dataTask?.suspend()
                main_async {
                    downloadModel.stateClosure?(.suspended)
                }
            })
            downloadingModels.removeAll()
        }
    }
    
    /**
     Resume a file download action with URL.
     
     @param url        The URL of the file which to be resumed.
     */
    public func resumeDownloadOfURL(_ url: URL) {
        guard let downloadModel = downloadModelsDic[url.lastPathComponent] else { return }
        
        var downloadState: MMDownloadState = .waiting
        if canResumeDownload() {
            downloadingModels.append(downloadModel)
            downloadModel.dataTask?.resume()
            downloadState = .running
        } else {
            waitingModels.append(downloadModel)
            downloadState = .waiting
        }
        
        main_async {
            downloadModel.stateClosure?(downloadState)
        }
    }
    
    /**
     Resume all files download action.
     */
    public func resumeAllDownloads() {
        if downloadModelsDic.count == 0 { return }
        
        downloadModelsDic.forEach { (key, downloadModel) in
            var downloadState: MMDownloadState = .waiting
            if canResumeDownload() {
                downloadingModels.append(downloadModel)
                downloadModel.dataTask?.resume()
                downloadState = .running
            } else {
                waitingModels.append(downloadModel)
                downloadState = .waiting
            }
            
            main_async {
                downloadModel.stateClosure?(downloadState)
            }
        }
    }
    
    /**
     Cancel a file download action with URL.
     
     @param url        The URL of the file which to be canceled.
     */
    public func cancelDownloadOfURL(_ url: URL) {
        guard let downloadModel = downloadModelsDic[url.lastPathComponent] else { return }
        guard let url = downloadModel.url else { return }
        
        downloadModel.closeOutputStream()
        downloadModel.dataTask?.cancel()
        
        main_async {
            downloadModel.stateClosure?(.canceled)
        }
        
        _ = waitingModels.remove(of: downloadModel)
        _ = downloadingModels.remove(of: downloadModel)
        downloadModelsDic.removeValue(forKey: url.lastPathComponent)
        
        resumeNextDowloadModel()
    }
    
    /**
     Cancel all files download action.
     */
    public func cancelAllDownloads() {
        if downloadModelsDic.count == 0 { return }
        
        downloadModelsDic.forEach { (key, downloadModel) in
            downloadModel.closeOutputStream()
            downloadModel.dataTask?.cancel()
            
            main_async {
                downloadModel.stateClosure?(.canceled)
            }
        }
        
        waitingModels.removeAll()
        downloadingModels.removeAll()
        downloadModelsDic.removeAll()
    }
    
    /**
     Delete a file with name.
     
     @param fileName        The name of the file which to be deleted.
     */
    public func deleteFile(_ fileName: String) {
        guard let filesTotalLength: NSMutableDictionary = NSMutableDictionary(contentsOfFile: filesTotalLengthPlistPath) else {
            return
        }
        
        filesTotalLength.removeObject(forKey: fileName)
        filesTotalLength.write(toFile: filesTotalLengthPlistPath, atomically: true)
        
        let dir = cachesDirectory.appendingPathComponent(saveFilesDirectory)
        let fileManager = FileManager.default
        do {
            let filePath = dir.appendingPathComponent(fileName).path
            print("Delete file: " + filePath)
            try fileManager.removeItem(atPath: filePath)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    /**
     Delete a file download action with URL and delete the file.
     
     @param url        The URL of the file which to be deleted.
     */
    public func deleteFileOfURL(_ url: URL?) {
        guard let url = url else { return }
        
        cancelDownloadOfURL(url)
        
        deleteFile(url.lastPathComponent)
    }
    
    /**
     Delete all files.
     */
    public func deleteAllFiles() {
        cancelAllDownloads()

        do {
            let dir = cachesDirectory.appendingPathComponent(saveFilesDirectory)
            let fileManager = FileManager.default
            
            let files = try fileManager.contentsOfDirectory((atPath: dir.path))
            files.forEach({
                do {
                    let filePath = dir.appendingPathComponent($0).path
                    print("Delete file: " + filePath)
                    try fileManager.removeItem(atPath: filePath)
                } catch let err {
                    print(err.localizedDescription)
                }
            })
        } catch let error {
            print(error.localizedDescription)
        }
        
    }
    
}

extension MMDownloadManager {
    
    public func getResourceFile(_ urlStr: String) -> URL? {
        guard let url = URL(string: urlStr) else { return nil }
        
        if isDownloadCompletedOfURL(url) { // 已完成的下载
            let filePath = fileFullPathOfURL(url)
            if FileManager.default.fileExists(atPath: filePath) {
                return filePath.toFileURL()
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
}
