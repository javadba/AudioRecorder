//
//  ViewController.swift
//  FDWaveformView
//
//  Created by William Entriken on 2/4/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol MiscUtils {
    func tp(_ msg: String)
    func ts() -> String
    typealias Fl = Float
}

extension MiscUtils {
//    func formatError(error: Error) {
//        if (notInited) {
//            Backtrace.install()
//        }
//        Backtrace.install()
//    }

    func ts() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-DD HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    func fileTs() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMDDHH_mmss"
        return formatter.string(from: Date())
    }

    func tp(_ msg: String) {
        print("[\(ts())] \(msg)")
    }

}

protocol MiscUtilsS {
    static func tps(_ msg: String)
    static func tss() -> String
    static func fileTss() -> String
    typealias Fl = Float
}

class MiscUtilsC : MiscUtils {
}

extension MiscUtilsS {
//    static let mu = MiscUtilsC()
    static func tps(_ msg: String) { let mu = MiscUtilsC(); mu.tp(msg) }
    static func tss() -> String { let mu = MiscUtilsC(); return mu.ts() }
    static func fileTss() -> String { let mu = MiscUtilsC(); return mu.fileTs() }

}


//
//
//class Ts {
//    lazy var fileDateFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HHmmss_SSS"
//        return formatter
//    }()
//
//    lazy var logDateFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MM-DD HH:mm:ss.SSS"
//        return formatter
//    }()
//
//    func ts() -> String {
//        return logDateFormatter.string(from: Date())
//    }
//}

