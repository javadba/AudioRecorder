//
//  ViewController.swift
//  AudioRecorder2
//
//  Created by Yaroslav Zhurakovskiy on 22.05.2020.
//  Copyright © 2020 Yaroslav Zhurakovskiy. All rights reserved.
//

import UIKit


//protocol MiscUtils {
//    func tp(_ msg: String)
//    func ts() -> String
//    typealias Fl = Float
//}
//
//extension MiscUtils {
//
//    func ts() -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MM-DD HH:mm:ss.SSS"
//        return formatter.string(from: Date())
//    }
//
//    func fileTs() -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMDDHH_mmss"
//        return formatter.string(from: Date())
//    }
//
//    func tp(_ msg: String) {
//        print("[\(ts())] \(msg)")
//    }
//
//}

class ViewController: UIViewController,  MiscUtils {
    private let recodignUseCase = RecodingUserCase()


    private func getTask(threadNum: Int, taskNum: Int) -> (() -> ())? {
        return {
            let interval = Double(Int.random(in: 1...6))
            self.tp("Thread\(threadNum)-Task=\(taskNum) starting for \(interval) seconds..")
            Thread.sleep(forTimeInterval: interval)
            self.tp("Thread\(threadNum)-Task=\(taskNum) for \(interval) seconds completed")
        }
    }

    @IBAction func runThreaded() {
        print("Threaded ..")
        let interval: TimeInterval = 3
        let nThreads = 4
        var taskNum = 1
        let nTasks = 3
        let threads = (1...nThreads).map { n -> Thread in
            let t = Thread {
                (1...nTasks).map { tnum in
                    let task = self.getTask(threadNum: n, taskNum: tnum)
                    task?()
                }
            }
            Thread.setThreadPriority(0.7)
            return t
        }
        print( "Threads: " + threads.map{n in "\(n)"}.joined(separator: ","))
        threads.map { t in t.start() }
        
        let waiter = Thread {
            for thread in threads {
                repeat {
                    Thread.sleep(forTimeInterval: 0.5)
                } while (!thread.isFinished)
                print("FINIHSED THREAD \(thread.name)!!")
            }
            print("FINIHSED ALL!")
        }
        waiter.start()
        
        
//        threads.map { t in
//            repeat {
//                Thread.sleep(forTimeInterval: 0.5)
//            } while (!t.isFinished)
//        }
//        threads.map{ t in print("t.finished: \(t.isFinished)")}
    }
    
    @IBAction func runThreadedDispatch() {
        DispatchQueue.global(qos: .default).async {
            let nThreads = 4
            var taskNum = 1
            let nTasks = 3
            
            let group = DispatchGroup()
            
            (1...nThreads).forEach { n in
                (1...nTasks).map { tnum in
                    group.enter()
                    DispatchQueue.global().async {
                        let task = self.getTask(threadNum: n, taskNum: tnum)
                        task?()
                        group.leave()
                    }
                }
                Thread.sleep(forTimeInterval: 0.5)
                
                print("Finished thread #\(n)")
            }
        
        
        
            group.wait()
            print("All tasks are done!")
        }
    }

    
    @IBAction func record() {
        recodignUseCase.startRecording()
       
    }
    
    @IBAction func stop() {
        recodignUseCase.stopRecording()
    }
}
