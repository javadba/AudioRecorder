//
//  ViewController.swift
//  AudioRecorder2
//
//  Created by Yaroslav Zhurakovskiy on 22.05.2020.
//  Copyright © 2020 Yaroslav Zhurakovskiy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private let samplesUploader = SamplesUploader()
    private let samplesWriter = SamplesFileWriter(
        filePath: {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let url = urls[0]
            return url.appendingPathComponent("samples.binary").path
        }()
    )

//    private let recoder = RecordAudio()
    private let recoder = AudioRecorderV2()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recoder.delegate = self
        
    }

    @IBAction func record() {
        recoder.startRecording { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                break // Do nothing
            case .audioUnitStartFailure(let status):
                let alert = UIAlertController(
                    title: "Error",
                    message: "OSStatus failure \(status)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
            case .permissionDenied:
                let alert = UIAlertController(
                    title: "Error",
                    message: "Permission denied",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
            case .failure(let error):
                let alert = UIAlertController(
                    title: "Error",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func stop() {
        recoder.stopRecording()
    }
}

extension ViewController: RecordAudioDelegate {
    func audioRecorder(_ audioRecorder: AudioRecorder, didReceiveSamples samples: Samples) {
        samplesWriter.write(samples)
        samplesUploader.upload(samples)
    }
}


extension ViewController: RecordAudioV2Delegate {
    func audioRecorder(_ audioRecorder: AudioRecorderV2, didReceiveSamples samples: Samples) {
        samplesWriter.write(samples)
        samplesUploader.upload(samples)
    }
}
