//
//  DownloadModel.swift
//  MeMe
//
//  Created by zhang yinglong on 2017/6/21.
//  Copyright © 2017年 sip. All rights reserved.
//

import Foundation

public enum MMDownloadState: Int {
    case waiting = 0
    case running = 1
    case suspended = 2
    case canceled = 3
    case completed = 4
    case failed = 5
}

public typealias StateClosure = (MMDownloadState) -> Void
public typealias ProgressClosure = (_ receivedSize: Int64, _ expectedSize: Int64, _ progress: Float) -> Void
public typealias CompletionClosure = (_ isSuccess: Bool, _ filePath: String?, _ error: Error?) -> Void

public class MMDownloadModel : NSObject {
    
    public var outputStream: OutputStream? = nil
    
    public var dataTask: URLSessionDataTask? = nil
    
    public var url: URL? = nil
    
    public var totalLength: Int64 = 0
    
    public var destPath: String? = nil
    
    public var state: MMDownloadState = .waiting
    
    public var stateClosure: StateClosure? = nil
    
    public var progressClosure: ProgressClosure? = nil
    
    public var completionClosure: CompletionClosure? = nil
    
    public func openOutputStream() {
        guard let outputStream = outputStream else { return }
        
        if outputStream.streamStatus == .notOpen {
            outputStream.open()
        }
    }
    
    public func closeOutputStream() {
        guard let outputStream = outputStream else { return }
        
        if outputStream.streamStatus != .closed {
            outputStream.close()
        }
    }
    
    public static func ==(lhs: MMDownloadModel, rhs: MMDownloadModel) -> Bool {
        return lhs.url == rhs.url
    }
}

//extension MMDownloadModel : Equatable {
//    
//    public static func ==(lhs: MMDownloadModel, rhs: MMDownloadModel) -> Bool {
//        return lhs.url == rhs.url
//    }
//    
//}
