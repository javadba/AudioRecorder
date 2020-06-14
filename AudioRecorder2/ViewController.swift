//
//  ViewController.swift
//  AudioRecorder2
//
//  Created by Yaroslav Zhurakovskiy on 22.05.2020.
//  Copyright © 2020 Yaroslav Zhurakovskiy. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MiscUtils {
    private let recorder = DataRecorder()
    private let audioRecorder = AudioRecorderV2()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func record() {
        recorder.startRecording()
        // TODO
//        { [weak self] result in
//            guard let self = self else {
//                return
//            }
//
//            switch result {
//            case .success:
//                break // Do nothing
//            case .audioUnitStartFailure(let status):
//                let alert = UIAlertController(
//                        title: "Error",
//                        message: "OSStatus failure \(status)",
//                        preferredStyle: .alert
//                )
//                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
//                self.present(alert, animated: true)
//            case .permissionDenied:
//                let alert = UIAlertController(
//                        title: "Error",
//                        message: "Permission denied",
//                        preferredStyle: .alert
//                )
//                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
//                self.present(alert, animated: true)
//            case .failure(let error):
//                let alert = UIAlertController(
//                        title: "Error",
//                        message: error.localizedDescription,
//                        preferredStyle: .alert
//                )
//                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
//                self.present(alert, animated: true)
//            }
//        }
    }

    @IBAction func stop() {
        recorder.stopRecording()
    }

    @IBAction func runThreaded() {
        return ThreadTests().runThreaded()
    }
    @IBAction func runThreadedDispatch() {
        return ThreadTests().runThreadedDispatch()
    }

}
