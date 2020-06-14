import UIKit

class ViewController: UIViewController,  MiscUtils {
    private let recorder = DataRecorder()


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
        print("Threads: " + threads.map { n in
            "\(n)"
        }.joined(separator: ","))
        threads.map { t in
            t.start()
        }

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
        recorder.startRecording()
       
    }
    
    @IBAction func stop() {
        recorder.stopRecording()
    }
}
