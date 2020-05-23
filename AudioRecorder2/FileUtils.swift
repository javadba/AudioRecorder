//
// Created by steve on 5/23/20.
// Copyright (c) 2020 steve. All rights reserved.
//

import Dispatch
import Foundation

class FileUtils: MiscUtilsS {
    class func write(_ path: String, _ data: String) {
        do {

            let fpath = getDocumentsDirectory().appendingPathComponent(path)
            tp("Writing \(data.count) bytes to \(fpath) ..")
            try data.data(using: .utf8)?.write(to: fpath)
        } catch let except {
            // failed to record!
            tp("Error in write/read\n" + except.localizedDescription)
        }

    }

    static func tstamp() -> TimeInterval {
        let ts = Date()
        return ts.timeIntervalSince1970
    }

    static func tp(_ msg: String) {
        tps(msg)
    }

    static func readFile(_ path: String) throws -> String {
        let nsPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        let furl = URL(fileURLWithPath: nsPath)
        let fpath = furl.appendingPathComponent(nsPath)
        tp("Reading from \(fpath) ..")
        let readBack = try String(contentsOf: fpath)
        tp("readBack len = \(readBack.count)")
        return readBack
    }

    static func readFileBytes(_ path: String) throws -> [UInt8] {
        let fstr = try FileUtils.readFile(path)
        return [UInt8](fstr.utf8)
    }
//    static func readFileBg(path: String) {
//        DispatchQueue.(delay: 1.0, background: {
//            let data = try! readFile(path)
//        }, completion: {
//            tp("Finished all")
//        })
//    }

    static func getBaseWriteURL() -> URL {
        let url = URL(string:NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])?.absoluteURL
        return url!
    }
    
    static func mkdir(_ dir: String) {
        let dataPath = getBaseWriteURL().appendingPathComponent(dir)
        if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
    }

    static func getWriteURL(_ subDir: String, _ fname: String, _ ext: String) -> URL {
        if (fname == "") {
            return URL(string:"file:///" + getBaseWriteURL().appendingPathComponent(subDir).absoluteString)!
        } else {
            return URL(string:"file:///" + getBaseWriteURL().appendingPathComponent(subDir)
                    .appendingPathComponent(fname).appendingPathExtension(ext).absoluteString)!
        }
    }


    static func getReadURL(_ subDir: String, _ fname: String, _ ext: String) -> URL {
//        let subDir = path.substring(from: 0, to: path.firstIndex(of: <#T##Element##Swift.String.Element#>))
        let url: URL = {
             if (subDir != "") {
                return Bundle.main.url(forResource: fname, withExtension: ext, subdirectory: subDir)!
            } else {
                return Bundle.main.url(forResource: fname, withExtension: ext)!
            }
        }()
        print("url=\(url)")
        return url
    }

    static func formatError(_ except: Error) -> String {
        return " ERROR: \(except.localizedDescription)"
    }

    static func writeFile( subDir: String,  fname: String,  data: String) {
        let url = getWriteURL(subDir, fname, "dat")
        print("Writing \(data.count) bytes to \(url.absoluteString) ..")
        DispatchQueue.background(delay: 1.0, background: {
            do {
                try data.data(using: .utf8)?.write(to: url)
            } catch let except {
                // failed to record!
                tp("Error in write/read to \(url): " + formatError(except))
            }
        }, completion: {
//            tp("Finished writing to \(url)")
        })
    }

    static func saveBlob(_ myBlob: String) {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        let furl = URL(fileURLWithPath: path)
        DispatchQueue.background(delay: 1.0, background: {
            do {
                for i in (1...0) {
                    let ts = Int(FileUtils.tstamp() * 200)
                    let fpath = furl.appendingPathComponent("breath.\(ts).audio")
                    tp("Saving \(myBlob.count)) bytes to \(fpath) loop#\(Int(i)) ..")
                    try myBlob.data(using: .utf8)?.write(to: fpath)
                    let readBack = try String(contentsOf: fpath)
                    tp("readBack len = \(readBack.count)")
                    let chatUrl = URL.init(string: "http://localhost:7094")!
                    tp("Sending Web Message to \(chatUrl) ..")
                    let contents = try String(contentsOf: chatUrl)
                    tp("Received \(contents)")
                }
            } catch let except {
                // failed to record!
                tp("Error in write/read\n" + except.localizedDescription)
            }
        }, completion: {
            tp("Finished all")
        })
    }

    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

}

extension DispatchQueue {
    static func background(delay: Double = 0.2, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
}

