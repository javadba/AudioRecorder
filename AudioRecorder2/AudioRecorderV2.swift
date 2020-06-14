//
//  AudioRecorderV2.swift
//  AudioRecorder2
//
// Derived from
// https://gist.github.com/hotpaw2/ba815fc23b5d642705f2b1dedfaf0107
//

import Foundation
import AudioUnit
import AVFoundation

protocol RecordAudioV2Delegate: class {
    func audioRecorder(_ audioRecorder: AudioRecorderV2, receivedSamples samples: Samples)
}

final class AudioRecorderV2 {
    private var auAudioUnit: AUAudioUnit! = nil
    
    private var enableRecording     = true
    private var audioSessionActive  = false
    private var audioSetupComplete  = false
    private var isRecording         = false
    
    private var sampleRate : Double =  44100.0      // desired audio sample rate
    
    private let circBuffSize        =  32768        // lock-free circular fifo/buffer size
    private var circBuffer          = [Float](repeating: 0, count: 32768)
    private var circInIdx  : Int    =  0            // sample input  index
    private var circOutIdx : Int    =  0            // sample output index
    
    private var audioLevel : Float  = 0.0
    
    private var micPermissionRequested  = false
    private var micPermissionGranted    = false
    
    // for restart from audio interruption notification
    private var audioInterrupted        = false
    
    private var renderBlock : AURenderBlock? = nil
    
    weak var delegate: RecordAudioV2Delegate?
    
    var userPermissionsGranted: Bool {
        return micPermissionGranted
    }
      
    func startRecording(completion: @escaping (StartAudioRecordingResult) -> Void) {
        guard !isRecording else {
            return
        }
        
        if !audioSessionActive {
            // configure and activate Audio Session, this might change the sampleRate
            setupAudioSessionForRecording(completion: completion)
        }
        
        guard micPermissionGranted && audioSessionActive else { return }
        
        let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32, // pcmFormatInt16, pcmFormatFloat32,
            sampleRate: sampleRate, // 44100.0 48000.0
            channels: 1, // 1 or 2
            interleaved: true // true for interleaved stereo
        )
        
        if auAudioUnit == nil {
            setupRemoteIOAudioUnitForRecord(audioFormat: audioFormat!)
        }
        
        renderBlock = auAudioUnit.renderBlock
        
        if (enableRecording
          && micPermissionGranted
          && audioSetupComplete
          && audioSessionActive
          && !isRecording) {
            auAudioUnit.inputHandler = { actionFlags, timestamp, frameCount, inputBusNumber in
                guard let renderBlock = self.renderBlock else {
                    return
                }
                
                var bufferList = AudioBufferList(
                    mNumberBuffers: 1,
                    mBuffers: AudioBuffer(
                        mNumberChannels: audioFormat!.channelCount,
                        mDataByteSize: 0,
                        mData: nil
                    )
                )
                let status = renderBlock(actionFlags, timestamp, frameCount, inputBusNumber, &bufferList, .none)
                if status == noErr {
                    self.recordMicrophoneInputSamples(
                        inputDataList: &bufferList,
                        frameCount: UInt32(frameCount)
                    )
                }
            }
            
            auAudioUnit.isInputEnabled  = true
            
            do {
                circInIdx = 0
                circOutIdx =  0
                try auAudioUnit.allocateRenderResources()
                try auAudioUnit.startHardware()
                isRecording = true
                completion(.success)
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    func stopRecording() {
        if isRecording {
            auAudioUnit.stopHardware()
            isRecording = false
        }
        
        if audioSessionActive {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(false)
            } catch /* let error as NSError */ {
            }
            audioSessionActive = false
        }
    }
    
    private func recordMicrophoneInputSamples(
        inputDataList : UnsafeMutablePointer<AudioBufferList>, // AudioBufferList*
        frameCount : UInt32 )
    {
        let ptrAudioBuffereList = UnsafeMutableAudioBufferListPointer(inputDataList)
        let audioBuffer = ptrAudioBuffereList[0]
        
        // float* ptrSamples = (float *)audioBuffer.mData;
        guard let ptrSamples = audioBuffer.mData?.assumingMemoryBound(to: Float.self) else { // float *
            return
        }
        
        // MARK: delegateToReceivedSamples
        delegate?.audioRecorder(
            self,
            receivedSamples: Samples(
                ptrSamples: ptrSamples,
                frameCount: Int(frameCount),
                numberChannels: Int(audioBuffer.mNumberChannels)
            )
        )
        
        var sum : Float32 = 0.0
        var currentCircInIdx = self.circInIdx
        for frameIndex in 0..<Int(frameCount / audioBuffer.mNumberChannels) {
            for channelIndex in 0..<Int(audioBuffer.mNumberChannels) {
                let sample = ptrSamples[frameIndex + channelIndex]
                self.circBuffer[currentCircInIdx + channelIndex] = sample
                sum += sample * sample
            }
            
            currentCircInIdx += Int(audioBuffer.mNumberChannels)
            if currentCircInIdx >= circBuffSize {
                currentCircInIdx = 0
            }
        }
        self.circInIdx = currentCircInIdx
        // measuredMicVol_1 = sqrt( Float(sum) / Float(count) ) // scaled volume
        if sum > 0.0 && frameCount > 0 {
            let tmp = 5.0 * (logf(sum / Float32(frameCount)) + 20.0)
            let r : Float32 = 0.2
            audioLevel = r * tmp + (1.0 - r) * audioLevel
        }
    }
    
    private func setupAudioSessionForRecording(completion: @escaping (StartAudioRecordingResult) -> Void) {
        do {
            
            let audioSession = AVAudioSession.sharedInstance()
            
            requestUserPermissions { granted in
                if !granted {
                    completion(.permissionDenied)
                }
            }
            
            if enableRecording {
                try audioSession.setCategory(.record)
            }
//            let preferredIOBufferDuration = 0.100  // 5.3 milliseconds = 256 samples
            let preferredIOBufferDuration = 0.0053  // 5.3 milliseconds = 256 samples
            try audioSession.setPreferredSampleRate(sampleRate) // at 48000.0
            try audioSession.setPreferredIOBufferDuration(preferredIOBufferDuration)
            
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: nil,
                using: myAudioSessionInterruptionHandler
            )
            try audioSession.setActive(true)
            audioSessionActive = true
            self.sampleRate = audioSession.sampleRate
        } catch let error {
            completion(.failure(error))
        }
    }
    
    // find and set up the sample format for the RemoteIO Audio Unit
    private func setupRemoteIOAudioUnitForRecord(audioFormat : AVAudioFormat) {
        do {
            let audioComponentDescription = AudioComponentDescription(
                componentType: kAudioUnitType_Output,
                componentSubType: kAudioUnitSubType_RemoteIO,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0 )
            
            
            try auAudioUnit = AUAudioUnit(componentDescription: audioComponentDescription)
            
            // bus 1 is for data that the microphone exports out to the handler block
            let bus1 = auAudioUnit.outputBusses[1]
            
            try bus1.setFormat(audioFormat)  //      for microphone bus
            audioSetupComplete = true
        } catch let error {
            print(error)
        }
    }
    
    private func myAudioSessionInterruptionHandler(notification: Notification) -> Void {
        let interuptionDict = notification.userInfo
        if let interuptionType = interuptionDict?[AVAudioSessionInterruptionTypeKey] {
            let interuptionVal = AVAudioSession.InterruptionType(
                rawValue: (interuptionType as AnyObject).uintValue )
            if (interuptionVal == AVAudioSession.InterruptionType.began) {
                // [self beginInterruption];
                if (isRecording) {
                    auAudioUnit.stopHardware()
                    isRecording = false
                    let audioSession = AVAudioSession.sharedInstance()
                    do {
                        try audioSession.setActive(false)
                        audioSessionActive = false
                    } catch {
                        // placeholder for error handling
                    }
                    audioInterrupted = true
                }
            } else if (interuptionVal == AVAudioSession.InterruptionType.ended) {
                // [self endInterruption];
                if (audioInterrupted) {
                    let audioSession = AVAudioSession.sharedInstance()
                    do {
                        try audioSession.setActive(true)
                        audioSessionActive = true
                        if (auAudioUnit.renderResourcesAllocated == false) {
                            try auAudioUnit.allocateRenderResources()
                        }
                        try auAudioUnit.startHardware()
                        isRecording = true
                    } catch {
                        // placeholder for error handling
                    }
                }
            }
        }
    }
    
    private func requestUserPermissions(copletionHandler: @escaping (_ granted: Bool) -> Void) {
        if !micPermissionGranted {
            if !micPermissionRequested {
                micPermissionRequested = true
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    if granted {
                        self.micPermissionGranted = true
                        DispatchQueue.main.async {
                            copletionHandler(granted)
                        }
                    } else {
                        self.enableRecording = false
                        DispatchQueue.main.async {
                            copletionHandler(granted)
                        }
                    }
                }
            }
        }
    }
}
