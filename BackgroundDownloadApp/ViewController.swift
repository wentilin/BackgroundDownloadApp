//
//  ViewController.swift
//  BackgroundDownloadApp
//
//  Created by wentilin on 15/7/14.
//  Copyright © 2015年 wentilin. All rights reserved.
//

import UIKit

enum CellTagValue: Int {
    case FileLabel = 10
    case StartPauseButton = 20
    case StopButton = 30
    case ProgressBar = 40
    case ReadyLabel = 50
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSURLSessionDownloadDelegate {

    @IBOutlet weak var filesTableView: UITableView!
    
    var session: NSURLSession?
    var fileDownloadDatas: [FileDownloadInfo] = []
    var docDirectoryURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeFileDownloadDatas()
        
        self.docDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first
        print(self.docDirectoryURL)
        
        self.filesTableView.delegate = self
        self.filesTableView.dataSource = self
        
        let sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("wentilin.BGDowload")
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 5
        self.session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    func initializeFileDownloadDatas() {
        self.fileDownloadDatas.append(FileDownloadInfo(title: "iOS Programming Guide", downloadSource: "https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/iPhoneAppProgrammingGuide.pdfr"))
        self.fileDownloadDatas.append(FileDownloadInfo(title: "Human Interface Guidelines", downloadSource: "https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/MobileHIG/MobileHIG.pdf"))
        self.fileDownloadDatas.append(FileDownloadInfo(title: "Networking Overview", downloadSource: "https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/NetworkingOverview.pdf"))
        self.fileDownloadDatas.append(FileDownloadInfo(title: "AV Foundation", downloadSource: "https://developer.apple.com/library/ios/documenta"))
        self.fileDownloadDatas.append(FileDownloadInfo(title: "iPhone User Guide", downloadSource: "https://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf"))
    }
    
    //start or pause the download
    @IBAction func startOrPauseDownloadingSingleFile(sender: AnyObject) {
        //Get the cell which contains the sender
        if (sender.superview!!.superview?.isKindOfClass(UITableViewCell.self) != nil) {
            let containerCell = sender.superview!!.superview! as! UITableViewCell
            //Get cell's indexPath
            let cellIndexPath = self.filesTableView.indexPathForCell(containerCell)
            let cellIndex = cellIndexPath?.row
            
            let fileDowdloadInfo = fileDownloadDatas[cellIndex!]
            if !fileDowdloadInfo.isDownloading {
                //If taskIdentifier==-1 then create a task
                if fileDowdloadInfo.taskIdentifier == -1 {
                    fileDowdloadInfo.downloadTask = self.session?.downloadTaskWithURL(NSURL(string: fileDowdloadInfo.downloadSource)!)
                    //retain a new taskIdentifier
                    fileDowdloadInfo.taskIdentifier = (fileDowdloadInfo.downloadTask?.taskIdentifier)!
                    
                    //start the task
                    fileDowdloadInfo.downloadTask?.resume()
                } else {
                    //The resume of download task will be done here
                    //task'resumedata maybe nil even though it have been created
                    if fileDowdloadInfo.taskResumeData != nil {
                        fileDowdloadInfo.downloadTask = self.session?.downloadTaskWithResumeData(fileDowdloadInfo.taskResumeData!)
                        fileDowdloadInfo.downloadTask?.resume()
                        
                        //Keep the new download tast indentifier
                        fileDowdloadInfo.taskIdentifier = (fileDowdloadInfo.downloadTask?.taskIdentifier)!
                    } else {
                        print("\(fileDowdloadInfo.downloadTask)--------->>>>>>")
                        fileDowdloadInfo.downloadTask?.cancel()
                        fileDowdloadInfo.taskIdentifier = -1
                    }
                }
            } else {
                //The pause of a download task will be done here
                fileDowdloadInfo.downloadTask?.cancelByProducingResumeData({ (data: NSData?) -> Void in
                    if data != nil {
                        fileDowdloadInfo.taskResumeData = NSData(data: data!)
                    }
                })
            }
            
            //Change the isDownloading property value
            fileDowdloadInfo.isDownloading = !fileDowdloadInfo.isDownloading
            
            //Reload the table view
            self.filesTableView.reloadRowsAtIndexPaths([cellIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    
    }
    
    //Stop downloading task
    @IBAction func stopDownloading(sender: AnyObject) {
        if sender.superview!!.superview!.isKindOfClass(UITableViewCell.self) {
            let containerCell = sender.superview!!.superview! as! UITableViewCell
            let cellIndexPath = self.filesTableView.indexPathForCell(containerCell)
            let cellIndex = cellIndexPath!.row
            
            let fileDownloadInfo = self.fileDownloadDatas[cellIndex]
            
            //Cancel the download task
            fileDownloadInfo.downloadTask?.cancel()
            
            //Change the related properties
            fileDownloadInfo.isDownloading = false
            fileDownloadInfo.taskIdentifier = -1
            fileDownloadInfo.downloadProgress = 0.0
            
            //Reload the table view
            self.filesTableView.reloadRowsAtIndexPaths([cellIndexPath!], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
   
    //Start all downloads
    @IBAction func startAllDownloads(sender: AnyObject) {
        for var i=0; i<self.fileDownloadDatas.count; i++ {
            let fileDownloadInfo = self.fileDownloadDatas[i]
            
            //Completed and downloading task would not start
            if !fileDownloadInfo.isDownloading && !fileDownloadInfo.downLoadComplete {
                if fileDownloadInfo.taskIdentifier == -1 {
                    fileDownloadInfo.downloadTask = self.session?.downloadTaskWithURL(NSURL(string: fileDownloadInfo.downloadSource)!)
                    
                } else {
                    //resume paused download task
                    if let resumeData = fileDownloadInfo.taskResumeData {
                        fileDownloadInfo.downloadTask = self.session?.downloadTaskWithResumeData(resumeData)
                    } else {
                        //Cancel and create again
                        fileDownloadInfo.downloadTask?.cancel()
                        fileDownloadInfo.taskIdentifier = -1
                    }
                }
                
                //Keep new taskIdentifier
                fileDownloadInfo.taskIdentifier = (fileDownloadInfo.downloadTask?.taskIdentifier)!
                
                //start download
                fileDownloadInfo.downloadTask?.resume()
                
                //Indicate for each file that is being downloaded
                fileDownloadInfo.isDownloading = true
            }
        }
        //Reload table view
        self.filesTableView.reloadData()
    }

    //Stop all downloads
    @IBAction func stopAllDownloads(sender: AnyObject) {
        for var i=0; i<self.fileDownloadDatas.count; i++ {
            let fileDownloadInfo = self.fileDownloadDatas[i]
            
            //Stop the download task which is not completed
            if !fileDownloadInfo.downLoadComplete {
                fileDownloadInfo.downloadTask?.cancel()
                
                //change all related properties
                fileDownloadInfo.isDownloading = false
                fileDownloadInfo.taskIdentifier = -1
                fileDownloadInfo.downloadProgress = 0.0
                fileDownloadInfo.downloadTask = nil
            }
        }
        //Reload the table view
        self.filesTableView.reloadData()
    }

    //Inilialize all download tasks
    @IBAction func initializeAll(sender: AnyObject) {
        for var i=0; i<self.fileDownloadDatas.count; i++ {
            let fileDownloadInfo = self.fileDownloadDatas[i]
            
            if fileDownloadInfo.isDownloading {
                fileDownloadInfo.downloadTask?.cancel()
            }
            
            fileDownloadInfo.isDownloading = false
            fileDownloadInfo.downLoadComplete = false
            fileDownloadInfo.taskIdentifier = -1
            fileDownloadInfo.downloadProgress = 0.0
            fileDownloadInfo.downloadTask = nil
        }
        //Reload table view
        self.filesTableView.reloadData()
    }
    
    //MARK: - tableView's DataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fileDownloadDatas.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("FileDownloadCellIdentifier")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "FileDownloadCellIdentifier")
        }
        
        let dowlownInfo = fileDownloadDatas[indexPath.row]
        
        let displayedTitile = cell?.viewWithTag(CellTagValue.FileLabel.rawValue) as? UILabel
        let startPauseButton = cell?.viewWithTag(CellTagValue.StartPauseButton.rawValue) as? UIButton
        let stopButton = cell?.viewWithTag(CellTagValue.StopButton.rawValue) as? UIButton
        let progressView = cell?.viewWithTag(CellTagValue.ProgressBar.rawValue) as? UIProgressView
        let readyLabel = cell?.viewWithTag(CellTagValue.ReadyLabel.rawValue) as? UILabel
        
        displayedTitile?.text = dowlownInfo.fileTitle
        
        var startPauseButtonImageName: String?
        
        if !dowlownInfo.isDownloading {
            progressView?.hidden = true
            stopButton?.enabled = false
            
            let hidControls = dowlownInfo.downLoadComplete ? true : false
            startPauseButton?.hidden = hidControls
            stopButton?.hidden = hidControls
            readyLabel?.hidden = !hidControls
            
            startPauseButtonImageName = "play-25"
        } else {
            progressView?.hidden = false
            progressView?.progress = dowlownInfo.downloadProgress
            
            stopButton?.enabled = true
            
            startPauseButtonImageName = "pause-25"
        }
        
        startPauseButton?.setImage(UIImage(named: startPauseButtonImageName!), forState: UIControlState.Normal)
        
        return cell!
    }
    
    //MARK: - NSURLSession Download Delegate
    
    //Copy the file when the task is finished
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let fileManager = NSFileManager.defaultManager()
        let destinationFilename = downloadTask.originalRequest?.URL?.lastPathComponent
        let destinationURL = self.docDirectoryURL?.URLByAppendingPathComponent(destinationFilename!)
        
        //Remove the file existing at stored directory
        if fileManager.fileExistsAtPath((destinationURL?.path)!) {
            do {
                try fileManager.removeItemAtURL(destinationURL!)
            } catch let error as NSError {
                print("Error: \(error.domain)")
            }
        }
        
        //Copy the downloaded file to stored directory
        do {
            try fileManager.copyItemAtURL(location, toURL: destinationURL!)
            let index = self.getFileDownloadInfoIndexWithTaskIdentifier(downloadTask.taskIdentifier)
            let fileDownloadInfo = self.fileDownloadDatas[index]
            fileDownloadInfo.isDownloading = false
            fileDownloadInfo.downLoadComplete = true
            
            fileDownloadInfo.taskIdentifier = -1
            fileDownloadInfo.taskResumeData = nil
            
            //Reload table view in main thread
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.filesTableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
            })
        } catch let error as NSError {
            print("Unable to copy temp file. Error: \(error.domain)")
        }
    }
    
    //Task may have error when it is completed
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            print("Download completed with error: \(error)")
        } else {
            print("Download finished successfully.")
        }
    }
    
    //Periodically informs the delegate about the download’s progress
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown {
            print("Unknown transfer size")
        } else {
            let index = getFileDownloadInfoIndexWithTaskIdentifier(downloadTask.taskIdentifier)
            let fileDownloadInfor = self.fileDownloadDatas[index]
            
            //Refresh prgress view in main thread
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                fileDownloadInfor.downloadProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                let cell = self.filesTableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0))
                let progressView = cell?.viewWithTag(CellTagValue.ProgressBar.rawValue) as! UIProgressView
                progressView.progress = fileDownloadInfor.downloadProgress
            })
        }
    }
    
    //Tells the delegate that all messages enqueued for a session have been delivered
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //Check if all download tasks have been finished
        self.session?.getTasksWithCompletionHandler({ (dataTasks: [NSURLSessionDataTask], uploadTask: [NSURLSessionUploadTask], downloadTasks: [NSURLSessionDownloadTask]) -> Void in
            print("-----------All have been downloaded-------------")
            if downloadTasks.count == 0 {
                if appDelegate.backgroundTransferCompletionHandler != nil {
                    let completionHandler = appDelegate.backgroundTransferCompletionHandler
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        completionHandler()
                        
                        //Present a localNifiction that notificate user that all tasks is finished
                        let localNotification = UILocalNotification()
                        localNotification.alertBody = "All files have been downloaded"
                        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
                    })
                }
            }
        })
    }
    
    //MARK: - Get download task indentifier
    func getFileDownloadInfoIndexWithTaskIdentifier(taskIdentifier: Int) -> Int{
        var index = 0
        for var i = 0;i < self.fileDownloadDatas.count; i++ {
            let fileDownloadInfo = self.fileDownloadDatas[i]
            if fileDownloadInfo.taskIdentifier == taskIdentifier {
                index = i
                break
            }
        }
        return index
    }
}