//
//  SamplesFileWriter.swift
//  AudioRecorder2
//
//  Created by Yaroslav Zhurakovskiy on 22.05.2020.
//  Copyright © 2020 Yaroslav Zhurakovskiy. All rights reserved.
//

import Foundation

class SamplesFileWriter {
    private var fileHandle: FileHandle!
    private let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
    }

    var cntr = 0
    func write(_ samples: Samples) {
        cntr += 1
        if (cntr % 100 == 1) {
            print("Writing \(samples.count) samples.. loop \(cntr)")
        }
        createFileHandleIfNeccessary()
        
        fileHandle.write(samples.makeData(copy: false))
    }
    
    private func createFileHandleIfNeccessary() {
        if fileHandle == nil {
            if !FileManager.default.fileExists(atPath: filePath) {
                FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
            }
            fileHandle = FileHandle(forWritingAtPath: filePath)!
            fileHandle.seekToEndOfFile()
        }
    }
}
