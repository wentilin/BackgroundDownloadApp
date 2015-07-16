//
//  FileDownloadInfo.swift
//  BackgroundDownloadApp
//
//  Created by wentilin on 15/7/15.
//  Copyright © 2015年 wentilin. All rights reserved.
//

import UIKit

class FileDownloadInfo: NSObject {
    var fileTitle: String
    var downloadSource: String
    var downloadTask: NSURLSessionDownloadTask?
    var taskResumeData: NSData?
    var downloadProgress: Float
    var isDownloading: Bool
    var downLoadComplete: Bool
    var taskIdentifier: Int
    
    init(title: String, downloadSource source: String) {
        fileTitle = title
        downloadSource = source
        downloadProgress = 0.0
        isDownloading = false
        downLoadComplete = false
        taskIdentifier = -1
    }
}
