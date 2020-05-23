//
//  SamplesUploader.swift
//  AudioRecorder2
//
//  Created by Yaroslav Zhurakovskiy on 22.05.2020.
//  Copyright © 2020 Yaroslav Zhurakovskiy. All rights reserved.
//

import Foundation
import ObjectiveC

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

//protocol HiThere: class {
//    func sayHi()
//    func printAttribute()
//}
//
//private let testKey = "HiThere.Key"
//extension HiThere {
//    var test: String {
//        set {
//            objc_setAssociatedObject(self, testKey, newValue, .OBJC_ASSOCIATION_COPY)
//        }
//        get {
//            return objc_getAssociatedObject(self, testKey) as! String
//        }
//    }
//    func sayHi() { print("hi") }
//    func printAttribute(obj: Any) { print("hi") }
//}

private class MyETLClass {
    open func saveToSpark(samples: Samples) -> Bool {
        print("Saved To Spark")
        return true
    }

}

private class UploadSamplesOperation: Operation {
    private static var lastId: Int = 0

//   private func synchronized<T>(lockObj: AnyObject!, closure: () throws -> T) rethrows ->  T {
//        objc_sync_enter(lockObj)
//        defer {
//            objc_sync_exit(lockObj)
//        }
//
//        return try closure()
//    }
//
    private static func nextId() -> Int {
        let lock = self
        objc_sync_enter(lock)
        defer{objc_sync_exit(lock)}
        lastId = lastId + 1
        return lastId
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
        self.id = Self.nextId()
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

        DispatchQueue.main.asyncAfter(deadline: .now() /*+ TimeInterval.random(in: 0..<5)*/) {
            print("Start uploading batch #\(self.id)\n")
            // TODO: put actual upload here
            Thread.sleep(forTimeInterval: Double(Int.random(in: 1...5)))
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
