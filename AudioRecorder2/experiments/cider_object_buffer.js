class CircularBuffer {

  initArr(m, n, initVal) {
    return [...Array(m)].map(() => [...Array(n)].map((x) => initVal))
  }

  initArrFn(m, n, fn) {
    return [...Array(m)].map(() => [...Array(n)].map((e, x) => {
      let y = fn(x + 1)
      return y
    }))
  }

  floatArrToArr(floatArr) {
    return [...Array(floatArr.length)].map(
      (x,i) => floatArr[i]
    )
  }
  arrToFloatArr(arr) {
    let floatArr = new Float32Array(1024);
    [...arr].map( (x,i) => floatArr[i] = x)
    return floatArr
  }

  p(msg) {
    if (printCntr % this.printSkips == 0) {
      if (!DisableAllPrinting) {
        console.log(msg)
      }
    }
    this.printCntr++
  }

  error(msg) {
    p(`Error: ${msg}`)
  }

  sleep = (milliseconds) => {
    return new Promise(resolve => setTimeout(resolve, milliseconds))
  }

// Copy full N audio samples from the smaller buffers into one of the full size buffs
  getFullBuffer(outBuf, bufs, pz, pza, N) {
    console.assert(this.bytesAvailable() >= N, 'insufficient bytes available for getFullBuffer')
    var sampleCnt = 0
    while (sampleCnt < N) {
      let bufx = Math.floor(((pz + sampleCnt) % this.FullSize) / this.Blen)
      // if buff is 0  then start = pz % this.Blen else it is 0
      // if buff is last one then end = [this.Blen - (pz % this.Blen)] else it is this.Blen
      let start = sampleCnt ? 0 : pz % this.Blen
      let end = N - sampleCnt <= this.Blen && pz % this.Blen ? pz % this.Blen : this.Blen
      let nSamps = end - start
      outBuf.splice(sampleCnt, nSamps, ...bufs[bufx].slice(start, end))
      // copyObjArray(outBuf,sampleCnt, nSamps, ...bufs[bufx].slice(start, end))
      sampleCnt += nSamps
      // XY
      // this.p(`bufx=${bufx} nSamps=${nSamps} sampleCnt=${sampleCnt} start=${start} end=${end} outBuf=${outBuf}`)
    }
    // console.assert(outBuf == '' + this.seq(pz + 1, pz + N), `getFullBuffer: outBuf incorrect for pz=${pz} pza=${pza} : ${outBuf}`)
    return outBuf
  }

// Dummy audio processor: just print it out
  processAudio(buf) {
    // this.p('processAudio bufs.last=' + buf[buf.length - 1] + ' buf=' + buf)
    return buf.length
  }

  bytesAvailable() {
    return this.pza - this.pz
  }

  push(newBuffer) {
    console.assert(newBuffer, `bufferLoop ERROR: New Buffer is empty`)
    let newDat = this.UseFloat32Array ? this.floatArrToArr(newBuffer) : newBuffer
    console.assert(newDat.length == this.Blen, `bufferLoop ERROR: New Buffer length is ${newDat.length}`)
    // this.p(`getnewBuffer this.pza=${this.pza} ${newDat}`)
    let bufx = Math.floor((this.pza % this.FullSize) / this.Blen)
    // this.p(`Producing audio into buffer[${bufx}]..`)
    // return produceAudio(bufs[bufx], len, cntr)
    this.bufs[bufx] = [...newDat]

    this.pza += newDat.length
  }

  processData(processorFn) {
    var outBuf = undefined
    let bytes = this.bytesAvailable()
    if (bytes >= N) {
      let fullBuf = this.getFullBuffer(this.fullSizeBufs[this.curFullBufx], this.bufs, this.pz, this.pza, this.N)
      outBuf = fullBuf
      this.curFullBufx = (this.curFullBufx + 1) % 2
      let processedBuf = processorFn(fullBuf) // processAudio(fullBuf)
      this.pz += this.Hop
      // this.p(`bytes processed ${processedBuf.length} + ${processedBuf.slice(0, 100)}`)
    } else {
      this.p(`Insufficient bytes available to processAudio: ${bytes}`)
    }
    return outBuf
  }

  pull() {
    var outBuf = undefined
    if (this.isFullBufAvailable()) {
      let bytes = this.bytesAvailable()
      outBuf = this.getFullBuffer(this.fullSizeBufs[this.curFullBufx], this.bufs, this.pz, this.pza, this.N)
      this.curFullBufx = (this.curFullBufx + 1) % 2
      this.pz += this.Hop
      // this.p(`bytes processed ${processedBuf.length} + ${processedBuf.slice(0, 100)}`)
    } else {
      this.p(`Insufficient bytes available to processAudio: ${bytes}`)
    }
    outBuf = this.UseFloat32Array ? this.arrToFloatArr(outBuf) : outBuf
    return outBuf
  }

  cntr() { return this.pza }

  constructor(bufSize, nBufs, N, hop, useFloat32Array = false,bufGenerator = undefined) {
    this.Blen = bufSize
    this.ActiveBufs = nBufs
    this.N = N
    this.Hop = hop
    this.bufGenerator = bufGenerator
    this.UseFloat32Array = useFloat32Array

    this.TotalBufs = this.ActiveBufs + 2
    this.FullSize = this.TotalBufs * this.Blen
    this.MaxIters = 10
    this.curFullBufx = 0
    this.PrintSkips = 1000

    // Global vars/pointers
    this.pz = 0
    this.pza = 0
    this.curFullBufx = 0
    var printCntr = 0

    this.bufs = this.initArr(this.TotalBufs, this.Blen, -1)
    this.fullSizeBufs = [...Array(2)].map((x) =>
      Array(N).fill(-1)
    )

  }

  isFullBufAvailable() {
    return this.bytesAvailable() >= this.N
  }
}
