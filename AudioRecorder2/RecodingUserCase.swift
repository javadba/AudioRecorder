//
//  RecodingUserCase.swift
//  AudioRecorder2
//
//  Created by steve on 5/22/20.
//  Copyright © 2020 Yaroslav Zhurakovskiy. All rights reserved.
//

import Foundation

class RecodingUserCase {
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
    
    func startRecording() {
        recoder.delegate = self

        recoder.startRecording { _ in
        }
    }
    
    func stopRecording() {
        recoder.stopRecording()
    }
}


extension RecodingUserCase: RecordAudioDelegate {
    func audioRecorder(_ audioRecorder: AudioRecorder, receivedSamples samples: Samples) {
//        samplesWriter.write(samples)
//        samplesUploader.upload(samples)
    }
    
}

// MARK: writerUploader
extension RecodingUserCase: RecordAudioV2Delegate {
    func audioRecorder(_ audioRecorder: AudioRecorderV2, receivedSamples samples: Samples) {
        samplesWriter.write(samples)
        samplesUploader.upload(samples)
    }
}
