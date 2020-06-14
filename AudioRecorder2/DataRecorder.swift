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
    
    //    private let recoder = RecordAudio()
    private let recorder = AudioRecorderV2()
    
    func startRecording() {
        recorder.delegate = self

        recorder.startRecording { _ in
        }
    }
    
    func stopRecording() {
        recorder.stopRecording()
    }
}


extension DataRecorder: RecordAudioDelegate {
    func audioRecorder(_ audioRecorder: AudioRecorder, receivedSamples samples: Samples) {
//        samplesWriter.write(samples)
//        samplesUploader.upload(samples)
    }
    
}

var iters:Int = 0
let MaxIters = 50

// MARK: writerUploader
extension DataRecorder: RecordAudioV2Delegate {

    func audioRecorder(_ audioRecorder: AudioRecorderV2, receivedSamples samples: Samples) {
        if (iters < MaxIters) {
            print("Executing iteration \(iters) ..")
            samplesWriter.write(samples)
            samplesUploader.upload(samples)
            iters  += 1
        }
    }
}
