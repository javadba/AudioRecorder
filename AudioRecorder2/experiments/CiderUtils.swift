//
// Created by steve on 6/14/20.
// Copyright (c) 2020 Yaroslav Zhurakovskiy. All rights reserved.
//

import Foundation

let DisableAllPrinting = false

func p(_ msg: String) {
    if (!DisableAllPrinting) {
        print(msg)
    }
}

struct Stats: CustomDebugStringConvertible, CustomStringConvertible {
    let counter: Int
    let bufSize: Int
    let mean: Float
    let stdev: Float
    let min: Float
    let max: Float
    let p1: Float
    let p10: Float
    let median: Float
    let p90: Float
    let p99: Float

    init(counter: Int, bufSize: Int, mean: Float, stdev: Float, min: Float, max: Float, p1: Float, p10: Float, median: Float, p90: Float, p99: Float) {
        self.counter = counter
        self.bufSize = bufSize
        self.mean = mean
        self.stdev = stdev
        self.min = min
        self.max = max
        self.p1 = p1
        self.p10 = p10
        self.median = median
        self.p90 = p90
        self.p99 = p99
    }

    var description: String {
        "Stats(counter: \(counter), bufSize: \(bufSize), mean: \(mean), stdev: \(stdev), min: \(min), max: \(max), p1: \(p1), p10: \(p10), median: \(median), p90: \(p90), p99: \(p99))"
    }
    var debugDescription: String {
        description
    }
}

class StatsHandler {

    public static var EnableStats = true
    typealias Num = Float32
    typealias Data = [Num]
    let name: String
    let maxSize: Int
    var skips: Int
    var cntr = 0
    var data: Data = []
    // TODO: change to Deque for better performance
//    let data: Deque<Num>

    init(_ name: String, _ maxSize: Int, _ skips: Int) {
        self.name = name
        self.maxSize = maxSize
        self.skips = skips
//        self.data =  Deque<Num>(minimumCapacity: maxSize)
    }

    func mean() -> Num {
        let arr = data
        return arr.reduce(0, { acc, val in acc + val }) / Float(arr.count)
    }

    func stddev() -> Num {
        if (data.count <= 1) {
            return 0
        } else {
            let m = self.mean();
            return sqrt(data.reduce(0, { sq, n in
                return sq + pow(n - m, 2)
            }) / Float(data.count - 1));
        }
    }

    func quantile(_ q: Float) -> Float {
        let arr = self.data
        let sorted = arr.sorted()
//    sorted.sort((a, b) => a - b)
        return sorted[Int(floor(q * (Float(arr.count) - 1)))]
    }


    func stats() -> Stats {
        let arr = self.data
        return Stats(
                counter: self.cntr,
                bufSize: self.data.count,
                mean: self.mean(),
                stdev: self.stddev(),
                min: arr.min()!,
                max: arr.max()!,
                p1: self.quantile(0.01),
                p10: self.quantile(0.1),
                median: self.quantile(0.5),
                p90: self.quantile(0.9),
                p99: self.quantile(0.99)
        )
    }

    public func statsToString() -> String {
        return stats().debugDescription
    }

    public func toLogString() -> String {
        return "[\(now())] \(self.name)-Stats \(self.cntr)] \(self.statsToString())"
    }

    func print() {
        p(toLogString())
    }

    public func push(_ stat: Num) {
        if (Self.EnableStats) {
            if (self.data.count >= self.maxSize) {
                self.data.remove(at: self.data.count)
            }
            data.insert(stat, at: 0)
            self.cntr += 1
            if (self.cntr % self.skips == 1) {
                self.print()
            }
        }
    }
}

func now() -> Int {
    return Int(Date().timeIntervalSince1970 * 1000)
}

func formattedDate() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "MM-dd HH24:mm:ss.SSSS"
    fmt.timeZone = TimeZone.current
//    return "\(Date().getFormattedDateString(format: "yyyy-MM-dd HH:mm:ss"))"
    return fmt.string(from: Date())
}


class PerfManager {
    public static let EnablePerf = true
    var starts: [String: Int] = [:]
    var stats: [String: StatsHandler] = [:]
    let maxSize: Int
    let printSkips: Int

    init(maxSize: Int = 1000, printSkips: Int = 1000) {
        self.maxSize = maxSize
        self.printSkips = printSkips
    }

    func start(name: String) {
        self.starts[name] = now()
    }

    func stop(name: String) {
        if (Self.EnablePerf) {
            if (self.stats[name] == nil) {
                self.stats[name] = StatsHandler("perf.\(name)", self.maxSize, self.printSkips)
            }
            self.stats[name]!.push(Float(now() - self.starts[name]!))
        }
    }

    func toString() -> String {
        let ms = stats.map{ k,v in "\(k)=> \(v.statsToString())"}.joined(separator: "\n")
        return "Perf - \(ms)"
    }

}