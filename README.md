## MMDownloadManager
轻量级 Swift 版下载管理器。[Object-C 版本](https://github.com/guowilling/SRDownloadManager)

## Installation

**CocoaPods**

> Add **pod 'MMDownloadManager', :git => 'https://github.com/zhangyinglong/MMDownloadManager.git'** to the Podfile, then run **pod install** in the terminal.
> 

**Carthage**
> Add **github "zhangyinglong/MMDownloadManager"** to the Cartfile, then run **carthage update --platform iOS** in the terminal.

**Manual**
> Drag the **MMDownloadManager** folder to the project.

## APIs
````swift
/**
Get MMDownloadManager instance.
*/
MMDownloadManager.default

/**
 The directory where the downloaded files are saved, default is .../Library/Caches/download if not setted.
 */
open var saveFilesDirectory: String = "download"

/**
 The count of max concurrent downloads, default is -1 which means no limit.
 */
open var maxConcurrentCount = -1

/**
 The mode of waiting for download queue, default is FIFO.
 */
open var waitingQueueMode: MMWaitingQueueMode = .fifo

/**
 Starts a file download action with URL, download state, download progress and download completion block.
 
 @param URL        The URL of the file which to be downloaded.
 @param destPath   The path to save the file after the download is completed, if pass nil file will be saved in default path.
 @param state      A block object to be executed when the download state changed.
 @param progress   A block object to be executed when the download progress changed.
 @param completion A block object to be executed when the download completion.
 */
public func downloadURL(_ url: URL, destPath: String? = nil, state: StateClosure? = nil, progress: ProgressClosure? = nil, completion: CompletionClosure? = nil)

/**
Suspend a file download action with URL.
     
@param url        The URL of the file which to be suspended.
*/
public func suspendDownloadOfURL(_ url: URL)

/**
Suspend all files download action.
*/
public func suspendAllDownloads()

/**
Resume a file download action with URL.
     
@param url        The URL of the file which to be resumed.
*/
public func resumeDownloadOfURL(_ url: URL)

/**
Resume all files download action.
*/
public func resumeAllDownloads()

/**
Cancel a file download action with URL.
     
@param url        The URL of the file which to be canceled.
*/
public func cancelDownloadOfURL(_ url: URL)    

/**
Cancel all files download action.
*/
public func cancelAllDownloads()

/**
Delete a file download action with URL and delete the file.
     
@param url        The URL of the file which to be deleted.
*/
public func deleteFileOfURL(_ url: URL?)

/**
Delete a file with name.
     
@param fileName        The name of the file which to be deleted.
*/
public func deleteFile(_ fileName: String)

/**
Delete all files.
*/
public func deleteAllFiles()
    
````

## Usage

````swift
MMDownloadManager.default.downloadURL(url, destPath: nil, state: { state in
                
}, progress: { (receivedSize, expectedSize, progress) in

}, completion: { (success, filePath, error) in

})
````

## License
MIT License

Copyright (c) 2017 zhangyinglong

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
