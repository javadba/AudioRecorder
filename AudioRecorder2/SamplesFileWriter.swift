//
//  SamplesFileWriter.swift
//  AudioRecorder2
//
//  Created by Yaroslav Zhurakovskiy on 22.05.2020.
//  Copyright © 2020 Yaroslav Zhurakovskiy. All rights reserved.
//

import Foundation

// import static FileUtils._

class SamplesFileWriter : MiscUtils {
    private typealias F = FileUtils
    private var fileHandle: FileHandle!
    private let filePath: String
    private let outDir : String = {
        "samples.\(FileUtils.fileTss())"
    }()
    
    init(filePath: String) {
        self.filePath = filePath
        F.mkdir(outDir)
    }

    var cntr = 0
    func write(_ samples: Samples) {
        cntr += 1
        if (cntr % 100 == 1) {
            print("Writing \(samples.count) samples.. loop \(cntr)")
        }
//        createFileHandleIfNeccessary()

    // let str = String(decoding: data, as: UTF8.self)


        let decoded = String(decoding: samples.makeData(copy: false), as: UTF8.self)
//        fileHandle.write(samples.makeData(copy: false))
        F.writeFile(subDir: outDir, fname: "samples\(F.fileTss())", data: decoded)
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
