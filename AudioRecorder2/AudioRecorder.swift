//
//  RecordAudio.swift
//
//  This is a Swift class (updated for Swift 5)
//    that uses the iOS RemoteIO Audio Unit
//    to record audio input samples,
//  (should be instantiated as a singleton object.)
//
//  Created by Ronald Nicholson on 10/21/16.
//  Copyright © 2017,2019 HotPaw Productions. All rights reserved.
//  http://www.nicholson.com/rhn/
//  Distribution permission: BSD 2-clause license
//

import Foundation
import AVFoundation
import AudioUnit

struct OSError: Error {
    let osStatus: OSStatus
}

protocol RecordAudioDelegate: class {
    func audioRecorder(_ audioRecorder: AudioRecorder, receivedSamples samples: Samples)
//    func  recorderDIdreceiveSamples()
}

final class AudioRecorder {
    private var audioUnit: AudioUnit?
    
    private var micPermissionAllowed = false
    private var sessionIsActive = false
    private(set) var isRecording = false
    
    private var sampleRate : Double = 44100.0    // default audio sample rate
    
    private let circBuffSize = 32768        // lock-free circular fifo/buffer size
    private var circBuffer   = [Float](repeating: 0, count: 32768)  // for incoming samples
    private var circInIdx  : Int =  0
    private var audioLevel : Float  = 0.0
    
    private let nChannels: UInt32 = 1
    
    private var hwSRate = 48000.0   // guess of device hardware sample rate
    private var micPermissionDispatchToken = 0
    private var interrupted = false     // for restart from audio interruption notification
         
    private var numberOfChannels: Int =  2
    
    private let outputBus: UInt32 = 0
    private let inputBus: UInt32 = 1
    
    var userPermissionsGranted: Bool {
        return micPermissionAllowed
    }
    
    weak var delegate: RecordAudioDelegate?
    
    func startRecording(completion: @escaping (StartAudioRecordingResult) -> Void) {
        guard !isRecording else {
            return
        }
        
        startAudioSession(completion: completion)
        if sessionIsActive {
            do {
                try startAudioUnit()
            } catch let error {
                let osError = error as! OSError
                completion(.audioUnitStartFailure(osError.osStatus))
            }
        }
    }
    
    private func startAudioUnit() throws {
        let audioUnit = try createNewOrReturnExistingAudioUnit()
        
        var status: OSStatus = noErr
        
        status = AudioUnitInitialize(audioUnit)
        if status != noErr {
            throw OSError(osStatus: status)
        }
        
        status = AudioOutputUnitStart(audioUnit)
        if status != status {
            throw OSError(osStatus: status)
        }
        
        isRecording = true
    }
    
    private func createNewOrReturnExistingAudioUnit() throws -> AudioUnit {
        if audioUnit == nil {
            audioUnit = try createAudioUnit()
        }
        return audioUnit!
    }
    
    private func startAudioSession(completion: @escaping (StartAudioRecordingResult) -> Void) {
        guard !sessionIsActive else {
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            requestUserPermissions { granted in
                if !granted {
                    completion(.permissionDenied)
                }
            }
                        
            if !micPermissionAllowed {
                completion(.permissionDenied)
                return
            }
            
            try audioSession.setCategory(.record)
            // choose 44100 or 48000 based on hardware rate
            // sampleRate = 44100.0
            var preferredIOBufferDuration = 0.0058      // 5.8 milliseconds = 256 samples
            hwSRate = audioSession.sampleRate           // get native hardware rate
            if hwSRate == 48000.0 {
                sampleRate = 48000.0
                preferredIOBufferDuration = 0.0053  // set session to hardware rate
            }
            
            let desiredSampleRate = sampleRate
            try audioSession.setPreferredSampleRate(desiredSampleRate)
            try audioSession.setPreferredIOBufferDuration(preferredIOBufferDuration)
            
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: nil,
                using: myAudioSessionInterruptionHandler
            )
            
            try audioSession.setActive(true)
            sessionIsActive = true
            completion(.success)
        } catch let error as NSError {
            completion(.failure(error))
        }
    }
    
    private func createAudioUnit() throws -> AudioUnit {
        var componentDesc = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Output),
            componentSubType: OSType(kAudioUnitSubType_RemoteIO),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: UInt32(0),
            componentFlagsMask: UInt32(0)
        )
        
        var osStatus: OSStatus = noErr
        
        let component: AudioComponent! = AudioComponentFindNext(nil, &componentDesc)
        
        var tempAudioUnit: AudioUnit?
        osStatus = AudioComponentInstanceNew(component, &tempAudioUnit)
        
        guard let audioUnit = tempAudioUnit else {
            throw OSError(osStatus: osStatus)
        }
        
        // Enable I/O for input.
        
        var one_ui32: UInt32 = 1
        osStatus = AudioUnitSetProperty(
            audioUnit,
            kAudioOutputUnitProperty_EnableIO,
            kAudioUnitScope_Input,
            inputBus,
            &one_ui32,
            UInt32(MemoryLayout<UInt32>.stride)
        )
        
        // Set format to 32-bit Floats, linear PCM
        var streamFormatDesc = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked,
            mBytesPerPacket: nChannels * UInt32(MemoryLayout<Float>.stride),
            mFramesPerPacket: 1,
            mBytesPerFrame: nChannels * UInt32(MemoryLayout<Float>.stride),
            mChannelsPerFrame: nChannels,
            mBitsPerChannel: 8 * UInt32(MemoryLayout<Float>.stride),
            mReserved: 0
        )
        
//        osErr = AudioUnitSetProperty(
//            au,
//            kAudioUnitProperty_StreamFormat,
//            kAudioUnitScope_Input,
//            outputBus,
//            &streamFormatDesc,
//            UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)
//        )

        osStatus = AudioUnitSetProperty(
            audioUnit,
            kAudioUnitProperty_StreamFormat,
            kAudioUnitScope_Output,
            inputBus,
            &streamFormatDesc,
            UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)
        )
        
        var inputCallbackStruct = AURenderCallbackStruct(
            inputProc: recordingCallback,
            inputProcRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        osStatus = AudioUnitSetProperty(
            audioUnit,
            AudioUnitPropertyID(kAudioOutputUnitProperty_SetInputCallback),
            AudioUnitScope(kAudioUnitScope_Global),
            inputBus,
            &inputCallbackStruct,
            UInt32(MemoryLayout<AURenderCallbackStruct>.stride)
        )
        
        // Ask CoreAudio to allocate buffers for us on render.
        // Is this true by default?
        osStatus = AudioUnitSetProperty(
            audioUnit,
            AudioUnitPropertyID(kAudioUnitProperty_ShouldAllocateBuffer),
            AudioUnitScope(kAudioUnitScope_Output),
            inputBus,
            &one_ui32,
            UInt32(MemoryLayout<UInt32>.stride)
        )
        
        if osStatus != noErr {
            throw OSError(osStatus: osStatus)
        }
        
        return audioUnit
    }
    
    private let recordingCallback: AURenderCallback = {
        (
            inRefCon,
            ioActionFlags,
            inTimeStamp,
            inBusNumber,
            frameCount,
            ioData
        ) -> OSStatus in
        
        let audioObject = Unmanaged<AudioRecorder>.fromOpaque(inRefCon).takeUnretainedValue()
        
        guard let audioUnit = audioObject.audioUnit else {
            return noErr
        }
        
        // set mData to nil, AudioUnitRender function should be allocating buffers
        var bufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: audioObject.nChannels,
                mDataByteSize: 0,
                mData: nil
            )
        )
        
        let status = AudioUnitRender(audioUnit, ioActionFlags, inTimeStamp, inBusNumber, frameCount, &bufferList)
        
        if status == noErr {
            audioObject.processMicrophoneBuffer(inputDataList: &bufferList, frameCount: UInt32(frameCount))
        }
        
        return status
    }
    
    private func processMicrophoneBuffer(
        inputDataList: UnsafeMutablePointer<AudioBufferList>,
        frameCount: UInt32
    ) {
        let ptrAudioBufferList = UnsafeMutableAudioBufferListPointer(inputDataList)
        let audioBuffer = ptrAudioBufferList[0]
        
        guard let ptrSamples = audioBuffer.mData?.assumingMemoryBound(to: Float.self) else {
            return
        }
        //MARK: delegate
        delegate?.audioRecorder(
            self,
            receivedSamples: Samples(
                ptrSamples: ptrSamples,
                frameCount: Int(frameCount),
                numberChannels: Int(audioBuffer.mNumberChannels)
            )
        )
        
        var sum : Float = 0.0
        
        var currentCircInIdx = circInIdx
        
        for frameIndex in 0..<Int(frameCount / audioBuffer.mNumberChannels) {
            for channelIndex in 0..<Int(audioBuffer.mNumberChannels) {
                let sample = ptrSamples[frameIndex + channelIndex]
                circBuffer[currentCircInIdx + channelIndex] = sample
                sum += sample * sample
            }
            
            currentCircInIdx += Int(audioBuffer.mNumberChannels) ;
            if currentCircInIdx >= circBuffSize {
                currentCircInIdx = 0
            }
        }
        circInIdx = currentCircInIdx
        
        // measuredMicVol_1 = sqrt( Float(sum) / Float(count) ) // scaled volume
        if sum > 0.0 && frameCount > 0 {
            let tmp = 5.0 * (logf(sum / Float(frameCount)) + 20.0)
            let r : Float = 0.2
            audioLevel = r * tmp + (1.0 - r) * audioLevel
        }
    }
    
    func stopRecording() {
        AudioUnitUninitialize(self.audioUnit!)
        isRecording = false
    }
    
    private func myAudioSessionInterruptionHandler(notification: Notification) -> Void {
        let interuptionDict = notification.userInfo
        if let interuptionType = interuptionDict?[AVAudioSessionInterruptionTypeKey] {
            let interuptionVal = AVAudioSession.InterruptionType(
                rawValue: (interuptionType as AnyObject).uintValue
            )
            if interuptionVal == .began {
                if isRecording {
                    stopRecording()
                    isRecording = false
                    let audioSession = AVAudioSession.sharedInstance()
                    do {
                        try audioSession.setActive(false)
                        sessionIsActive = false
                    } catch {
                    }
                    interrupted = true
                }
            } else if interuptionVal == .ended {
                if interrupted {
                    // potentially restart here
                }
            }
        }
    }
    
    private func requestUserPermissions(completionHandler: @escaping (_ granted: Bool) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        
        if !micPermissionAllowed {
            if micPermissionDispatchToken == 0 {
                micPermissionDispatchToken = 1
                audioSession.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        completionHandler(granted)
                    }
                }
            }
        }
    }
}
