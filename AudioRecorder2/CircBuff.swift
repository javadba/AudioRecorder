import Foundation

public class CircularBuffer {

    typealias Num = Float32
    typealias Numarr = [Num]

    func initArr(m: Int, n: Int, initVal: Num) -> [Numarr] {
        return (0..<m).map { _ in
            (0..<n).map { _ in
                initVal
            }
        }
    }

    func p(_ msg: String) {
        if (self.printCntr % self.PrintSkips == 0) {
            if (!DisableAllPrinting) {
                print(msg)
            }
        }
        self.printCntr += 1
    }

    func error(_ msg: String) {
        p("Error: \(msg)")
    }

// Copy full N audio samples from the smaller buffers into one of the full size buffs
    func getFullBuffer(outBuf: Numarr, bufs: [Numarr], pz: Int, pza: Int, N: Int) -> Numarr {
        var outBuf = outBuf
        assert(self.bytesAvailable() >= N, "insufficient bytes available for getFullBuffer")
        let sampleCnt = 0
//        while (sampleCnt < N) {
            let bufx = Int(floor(Float((pz + sampleCnt) % self.FullSize) / Float(self.Blen)))
            let start = sampleCnt>0 ? 0 : pz % self.Blen
            let end = N - sampleCnt <= self.Blen && (pz % self.Blen > 0) ? pz % self.Blen : self.Blen
            let nSamps = end - start
            copyToArr(bufs[bufx], sampleCnt, nSamps, outBuf, start)
//            sampleCnt += nSamps
            return outBuf
//        }
    }

    func bytesAvailable() -> Int {
        return pza - pz
    }

    func push(newBuf: Numarr) {
        assert(!newBuf.isEmpty, "bufferLoop ERROR: New Buffer is empty")
//        assert(newBuf.count == self.Blen, "bufferLoop ERROR: New Buffer length is \(newBuf.count)")
        let newlen = newBuf.count
        var consumed = 0
        while (consumed < newlen) {
//            consumed  self.Blen - Int(Float(pza % self.Blen))
            let inOffset = consumed
            let outOffset = pza % self.Blen
            let toCopy = min(self.Blen - outOffset, newlen - consumed)
            let bufx = Int(floor(Float(pza % self.FullSize) / Float(self.Blen)))
            let copied = copyToArr(newBuf, inOffset, toCopy, self.bufs[bufx], outOffset)
            consumed += copied
            pza += copied
        }
    }

    enum CircBuffErrors: Error {
        case runtimeError(String)
    }

    func pull() throws -> Numarr {
        var outBuf: [Num]
        if (self.isFullBufAvailable()) {
            outBuf = self.getFullBuffer(outBuf: self.fullSizeBufs[self.curFullBufx], bufs: self.bufs, pz: pz, pza: pza, N: self.N)
            self.curFullBufx = (self.curFullBufx + 1) % 2
            pz += self.Hop
            // self.p("bytes processed ${processedBuf.count} + ${processedBuf.slice(0, 100)}")
            return outBuf
        } else {
            let msg = "Insufficient bytes available to processAudio: \(self.bytesAvailable()) }"
            error(msg)
            throw CircBuffErrors.runtimeError(msg)
        }
    }

    func cntr() -> Int {
        return pza
    }

    let Blen: Int
    let ActiveBufs: Int
    let N: Int
    let Hop: Int
    let TotalBufs: Int
    let FullSize: Int
    let MaxIters = 10
    let PrintSkips = 1000
    var curFullBufx = 0
    var pz = 0
    var pza = 0
    var printCntr = 0
    var bufs: [Numarr]
    var fullSizeBufs: [Numarr]

    init(bufSize: Int, nBufs: Int, N: Int, hop: Int) {
        self.Blen = bufSize
        self.ActiveBufs = nBufs
        self.N = N
        self.Hop = hop

        self.TotalBufs = self.ActiveBufs + 2
        self.FullSize = self.TotalBufs * self.Blen

        // Global vars/pointers

        self.bufs = [] // self.initArr(m: self.TotalBufs, n: self.Blen, initVal: -1)
        self.fullSizeBufs = []
        // ...Array(2)].map((x) =>
//                Array(N).fill(-1)
//        )
        self.curFullBufx = 0
        self.pz = 0
        self.pza = 0
        self.printCntr = 0
    }

    func isFullBufAvailable() -> Bool {
        return self.bytesAvailable() >= self.N
    }

    func copyToArr(_ inBuf: [CircularBuffer.Num], _ inStart: Int, _ count: Int, _ toBuf: [Num], _ toStart: Int) -> Int {
        var toBuf: [Num] = toBuf
//        outBuf.replaceSubrange(sampleCnt..<sampleCnt+nSamps, with: bufs[bufx][start..<end])
        toBuf.replaceSubrange(toStart..<toStart+count, with: inBuf[inStart..<inStart+count])
        return count
    }
}
