import Foundation

class Samples {
    // TODO: Who ownes this memory?
    private let ptrSamples: UnsafePointer<Float>
    
    let frameCount: Int
    let numberChannels: Int
    
    init(ptrSamples: UnsafePointer<Float>, frameCount: Int, numberChannels: Int) {
        self.ptrSamples = ptrSamples
        self.frameCount = frameCount
        self.numberChannels = numberChannels
    }
    
    var count: Int {
        return frameCount * numberChannels
    }
    
    subscript(_ index: Int) -> Float {
        get {
            precondition(index >= 0 && index < count, "Wrong sample index \(index)")
            
            return ptrSamples[index]
        }
    }
     
    func makeData(copy: Bool) -> Data {
        if copy {
            return Data(
                bytes: UnsafeRawPointer(ptrSamples),
                count: count * MemoryLayout<Float>.stride
            )
        } else {
            return Data(
                bytesNoCopy: UnsafeMutableRawPointer(mutating: ptrSamples),
                count: count * MemoryLayout<Float>.stride,
                deallocator: .none
            )
        }
    }
}

extension Samples: Sequence {
    typealias Element = Float
    
    class Iterator : IteratorProtocol {
        typealias Element = Float
        
        private let ptrSamples: UnsafePointer<Float>
        private let count: Int
        private var index: Int
        
        init(ptrSamples: UnsafePointer<Float>, count: Int) {
            self.ptrSamples = ptrSamples
            self.count = count
            self.index = 0
        }
        
        func next() -> Float? {
            if index >= count {
                return nil
            }
            
            let next = ptrSamples[index]
            index += 1
            return next
        }
    }
    
    func makeIterator() -> Iterator {
        return Iterator(ptrSamples: ptrSamples, count: count)
    }
}
