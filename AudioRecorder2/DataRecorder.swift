//
//  RecodingUserCase.swift
//  AudioRecorder2
//

import Foundation

class DataRecorder {
    private let samplesUploader = SamplesUploader()
    private let samplesWriter = SamplesFileWriter(
        filePath: {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let url = urls[0]
            return url.appendingPathComponent("samples.binary").path
        }()
    )

    private let audioRecorder = AudioRecorderV2()
    
    func startRecording() {
        audioRecorder.delegate = self

        audioRecorder.startRecording()
        // TODO: I can't figure out how to incorporate this code
        //  originally in ViewController
//        audioRecorder.startRecording((StartAudioRecordingResult) ->
//                     { [weak self] result in self.audioRecorder.startRecording(
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
//        })
//        })
    }
    func stopRecording() {
        audioRecorder.stopRecording()
    }
}


extension DataRecorder: RecordAudioDelegate {
    func audioRecorder(_ audioRecorder: AudioRecorder, receivedSamples samples: Samples) {
//        samplesWriter.write(samples)
//        samplesUploader.upload(samples)
    }
    
}

var iters:Int = 0
let MaxIters = 20000
let PrintSkips = 500

// MARK: writerUploader
extension DataRecorder: RecordAudioV2Delegate {

    func audioRecorder(_ audioRecorder: AudioRecorderV2, receivedSamples samples: Samples) {
        if (iters < MaxIters) {
            if (iters % PrintSkips == 0) {
                print("Executing iteration \(iters) ..")
            }
            samplesWriter.write(samples)
            samplesUploader.upload(samples)
            iters  += 1
        }
    }
}
