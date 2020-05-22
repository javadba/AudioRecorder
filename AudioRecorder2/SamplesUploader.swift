//
//  SamplesUploader.swift
//  AudioRecorder2
//
//  Created by Yaroslav Zhurakovskiy on 22.05.2020.
//  Copyright © 2020 Yaroslav Zhurakovskiy. All rights reserved.
//

import Foundation

class SamplesUploader {
    private let queue: OperationQueue
    
    init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
    }
    
    func upload(_ samples: Samples) {
        queue.addOperation(UploadSamplesOperation(samples: samples))
    }
}

private class UploadSamplesOperation: Operation {
    private static var lastId: Int = 0
    private static func nextId() -> Int {
        let id = lastId + 1
        lastId = id
        return id
    }
    
    private let id: Int
    private let samples: Samples
    
    private var task: URLSessionDataTask?
    
    private var _isFinished: Bool
    private var _isExecuting: Bool
    
    init(samples: Samples) {
        self.samples = samples
        self._isFinished = false
        self._isExecuting = false
        self.id = Self.lastId + 1
        Self.lastId = Self.nextId()
        super.init()
    }
    
    override var isFinished: Bool {
        return _isFinished
    }
    
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    override func start() {
        print("Started uploading batch #\(id)")
        setIsExecuting(true)
        
        // Simulate uploading
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval.random(in: 0..<5)) {
            self.setIsExecuting(false)
            self.setIsFinished(true)
            print("Finished uploading batch #\(self.id)\n")
        }
    }
    
    private func setIsExecuting(_ value: Bool) {
        willChangeValue(for: \.isExecuting)
        _isExecuting = false
        didChangeValue(for: \.isExecuting)
    }
    
    private func setIsFinished(_ value: Bool) {
        willChangeValue(for: \.isFinished)
        _isFinished = true
        didChangeValue(for: \.isFinished)
    }
    
    override func cancel() {
        super.cancel()
        
        task?.cancel()
        setIsExecuting(false)
        setIsFinished(false)
        
    }
}
