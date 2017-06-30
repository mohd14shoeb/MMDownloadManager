//
//  ViewController.swift
//  downloadtest
//
//  Created by zhang yinglong on 2017/6/21.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

import UIKit
import MMDownloadManager

private let downloadURLString1 = "http://yxfile.idealsee.com/9f6f64aca98f90b91d260555d3b41b97_mp4.mp4"
private let downloadURLString2 = "http://yxfile.idealsee.com/31f9a479a9c2189bb3ee6e5c581d2026_mp4.mp4"
private let downloadURLString3 = "http://yxfile.idealsee.com/d3c0d29eb68dd384cb37f0377b52840d_mp4.mp4"

class ViewController: UIViewController {

    @IBOutlet weak var downloadButton1: UIButton!
    
    @IBOutlet weak var downloadButton2: UIButton!
    
    @IBOutlet weak var downloadButton3: UIButton!
    
    @IBOutlet weak var progressView1: UIProgressView!
    
    @IBOutlet weak var progressView2: UIProgressView!
    
    @IBOutlet weak var progressView3: UIProgressView!
    
    @IBOutlet weak var progressLabel1: UILabel!
    
    @IBOutlet weak var progressLabel2: UILabel!
    
    @IBOutlet weak var progressLabel3: UILabel!
    
    @IBOutlet weak var totalSizeLabel1: UILabel!
    
    @IBOutlet weak var totalSizeLabel2: UILabel!
    
    @IBOutlet weak var totalSizeLabel3: UILabel!
    
    @IBOutlet weak var currentSizeLabel1: UILabel!
    
    @IBOutlet weak var currentSizeLabel2: UILabel!
    
    @IBOutlet weak var currentSizeLabel3: UILabel!
    
    fileprivate lazy var manager: MMDownloadManager = MMDownloadManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        manager.maxConcurrentCount = 2
        manager.waitingQueueMode = .filo
        
        if let url = downloadURLString1.toURL() {
            let progress = manager.fileHasDownloadedProgressOfURL(url)
            progressView1.progress = progress
            progressLabel1.text = String(format: "%.f%%", progress * 100)
            downloadButton1.setTitle("Start", for: .normal)
        }
        
        if let url = downloadURLString2.toURL() {
            let progress = manager.fileHasDownloadedProgressOfURL(url)
            progressView2.progress = progress
            progressLabel2.text = String(format: "%.f%%", progress * 100)
            downloadButton2.setTitle("Start", for: .normal)
        }
        
        if let url = downloadURLString3.toURL() {
            let progress = manager.fileHasDownloadedProgressOfURL(url)
            progressView3.progress = progress
            progressLabel3.text = String(format: "%.f%%", progress * 100)
            downloadButton3.setTitle("Start", for: .normal)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func downloadFile1(_ sender: Any) {
        guard let url = downloadURLString1.toURL() else { return }
        
        download(url, totalSizeLabel1, currentSizeLabel1, progressLabel1, progressView1, downloadButton1)
    }
    
    @IBAction func downloadFile2(_ sender: Any) {
        guard let url = downloadURLString2.toURL() else { return }
        
        download(url, totalSizeLabel2, currentSizeLabel2, progressLabel2, progressView2, downloadButton2)
    }
    
    @IBAction func downloadFile3(_ sender: Any) {
        guard let url = downloadURLString3.toURL() else { return }
        
        download(url, totalSizeLabel3, currentSizeLabel3, progressLabel3, progressView3, downloadButton3)
    }
    
    @IBAction func deleteFile1(_ sender: Any) {
    
        manager.deleteFileOfURL(downloadURLString1.toURL())
        
        progressView1.progress = 0.0
        currentSizeLabel1.text = "0"
        totalSizeLabel1.text = "0"
        progressLabel1.text = "0%"
        downloadButton1.setTitle("Start", for: .normal)
    }
    
    @IBAction func deleteFile2(_ sender: Any) {
        
        manager.deleteFileOfURL(downloadURLString2.toURL())
        
        progressView2.progress = 0.0
        currentSizeLabel2.text = "0"
        totalSizeLabel2.text = "0"
        progressLabel2.text = "0%"
        downloadButton2.setTitle("Start", for: .normal)
    }
    
    @IBAction func deleteFile3(_ sender: Any) {
        
        manager.deleteFileOfURL(downloadURLString3.toURL())
        
        progressView3.progress = 0.0
        currentSizeLabel3.text = "0"
        totalSizeLabel3.text = "0"
        progressLabel3.text = "0%"
        downloadButton3.setTitle("Start", for: .normal)
    }
    
    @IBAction func suspendAllDownloads(_ sender: Any) {
        manager.suspendAllDownloads()
    }
    
    @IBAction func resumeAllDownloads(_ sender: Any) {
        manager.resumeAllDownloads()
    }
    
    @IBAction func cancelAllDownloads(_ sender: Any) {
        manager.cancelAllDownloads()
    }
    
    @IBAction func deleteAllFiles(_ sender: Any) {
        manager.deleteAllFiles()
        
        progressView1.progress = 0.0
        currentSizeLabel1.text = "0"
        totalSizeLabel1.text = "0"
        progressLabel1.text = "0%"
        downloadButton1.setTitle("Start", for: .normal)
        
        progressView2.progress = 0.0
        currentSizeLabel2.text = "0"
        totalSizeLabel2.text = "0"
        progressLabel2.text = "0%"
        downloadButton2.setTitle("Start", for: .normal)
        
        progressView3.progress = 0.0
        currentSizeLabel3.text = "0"
        totalSizeLabel3.text = "0"
        progressLabel3.text = "0%"
        downloadButton3.setTitle("Start", for: .normal)
    }
    
}

extension ViewController {
    
    fileprivate func download(_ url: URL, _ totalSizeLabel: UILabel, _ currentSizeLabel: UILabel, _ progressLabel: UILabel, _ progressView: UIProgressView, _ button: UIButton) {
        
        if button.currentTitle == "Start" {
            manager.downloadURL(url,
                                destPath: nil,
                                state: { state in
                button.setTitle(ViewController.titleWithDownloadState(state), for: .normal)
            }, progress: { (receivedSize, expectedSize, progress) in
                currentSizeLabel.text = String(format: "%zdMB", receivedSize / 1024 / 1024)
                totalSizeLabel.text = String(format: "%zdMB", expectedSize / 1024 / 1024)
                progressLabel.text = String(format: "%.f%%", progress * 100)
                print("\(url.lastPathComponent) download progress = \(progress)")
                progressView.progress = progress
            }, completion: { (success, filePath, error) in
                if success {
                    print("FilePath: " + filePath!)
                } else {
                    print(error ?? "unknown error")
                }
            })
        } else if button.currentTitle == "Waiting" {
            manager.cancelDownloadOfURL(url)
        } else if button.currentTitle == "Pause" {
            manager.suspendDownloadOfURL(url)
        } else if button.currentTitle == "Resume" {
            manager.resumeDownloadOfURL(url)
        } else if button.currentTitle == "Finish" {
            print("File has been downloaded! It's path is:" + manager.fileFullPathOfURL(url))
        }

    }
    
    class func titleWithDownloadState(_ state: MMDownloadState) -> String {
        switch state {
        case .waiting:
            return "Waiting"
        case .running:
            return "Pause"
        case .suspended:
            return "Resume"
        case .canceled:
            return "Start"
        case .completed:
            return "Finish"
        case .failed:
            return "Start"
        }
    }
    
}
