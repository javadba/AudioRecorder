function p(msg) {
  if (printCntr % this.printSkips == 0) {
    console.log(msg)
  }
  this.printCntr++
}

function produceAudio(buf, len, cntr) {
  buf.splice(0, buf.length, ...this.seq(cntr, cntr + len - 1))
  return buf
}

// Dummy audio processor: just print it out
function processAudio(buf) {
  // this.p('processAudio this.bufs.last=' + buf[buf.length - 1] + ' buf=' + buf)
  return buf.map((e, i) => 1e4 + e)
}

function produceStr(buf, len, cntr) {
  buf.splice(0, buf.length, ...this.seq(cntr, cntr + len - 1).map((x) => "def" + x))
  return buf
}

// Dummy audio processor: just print it out
function processStr(buf) {
  // this.p('processAudio this.bufs.last=' + buf[buf.length - 1] + ' buf=' + buf)
  return buf.map((e, i) => "abc" + 1e4 + e)
}


// Dummy audio processor: just print it out
function processObjects(buf) {
  // this.p('processAudio this.bufs.last=' + buf[buf.length - 1] + ' buf=' + buf)
  return buf.map((e, i) => {
    return {
      'real': initArr(fftSize / 2, i),
      'imag': initArr(fftSize / 2, i),
      'phase': initArr(fftSize / 2, i),
      'spectrum': initArr(fftSize / 2, i),
    }
  })
}


let fftSize = 8


function produceObjects(buf, len, cntr) {
  buf.splice(0, buf.length, ...this.seq(cntr, cntr + len - 1).map((x) => {
    return {
      'real': initArr(fftSize / 2, cntr),
      'imag': initArr(fftSize / 2, cntr),
      'phase': initArr(fftSize / 2, cntr),
      'spectrum': initArr(fftSize / 2, cntr),
    }
  }))
  return buf
}


// Constants
let Full = false
let N = Full ? 2048 : 16
let bufSize = Full ? 512 : 4
let hop = Full ? 441 : 3
let nBufs = N / bufSize
let MaxIters = 10
bufGenerator = produceObjects
consumeBuffer = processObjects


function jsonVal(initVal) {
  return {
    'real': initArr(fftSize / 2, initVal),
    'imag': initArr(fftSize / 2, initVal),
    'phase': initArr(fftSize / 2, initVal),
    'spectrum': initArr(fftSize / 2, initVal),
  }
}

function produceAudio(buf, len, cntr) {
  buf.splice(0, buf.length, ...seq(cntr, cntr + len - 1))
  return buf
}

// Gen Synthetic buffer data
function getNewBuffer(len, cntr) {
  let bufx = Math.floor((cntr % this.FullSize) / this.Blen)
  // this.p(`Producing audio into buffer[${bufx}]..`)
  // return produceAudio(bufs[bufx], len, cntr)
  return produceAudio(this.bufs[bufx], len, cntr)
}

var printCntr = 0
let printSkips = 50

function *buildBuf(Blen, circBuf, pushToOutputRingBuffer = false) {
  let input = produceAudio(Array(Blen).fill(-1),Blen, circBuf.cntr()+1)
  let output = Array(Blen * 4).fill(-1)
  while (circBuf.isFullBufAvailable()) {
    if (printCntr % printSkips == 0) {
      console.log(`Processing falling behind incident ${printCntr + 1}: dropping oldest buffer..`)
    }
    printCntr++
    let droppedData = circBuf.pull()
  }
  circBuf.push(input)

  // Process only if we have enough frames for the kernel.
  while (circBuf.isFullBufAvailable()) {
    let buf = circBuf.pull()
    output.splice(0, buf.length, ...buf)
    if (pushToOutputRingBuffer) {
      // Fill the output ring buffer with the processed data.
      //  push(this._heapOutputBuffer.getChannelData());
    }
    yield output
  }
}

// Dummy audio processor: just print it out
function processAudio(buf) {
  // this.p('processAudio this.bufs.last=' + buf[buf.length - 1] + ' buf=' + buf)
  return buf.map((e, i) => 1e4 + e)
}

// General purpose / utility methods
function seq(a, b) {
  return [...Array(b - a + 1)].map((_, i) => a + i)
}


function circTest() {
  // Constants
  let Full = false
  let N = Full ? 2048 : 16
  let bufSize = Full ? 512 : 4
  let Hop = Full ? 411 : 3
  let nBufs = N / bufSize
  let MaxIters = 10
  bufGenerator = produceAudio
  consumeBuffer = processAudio

  let Blen = 8
  let pza = 0

  // Main Processing loop for testing
  function* mainLoop(circbuf, maxIters) {
    for (let it = 0; it < maxIters; it++) {
      let bytes = circbuf.bytesAvailable()
      if (bytes >= N) {
        let fullBuf = circbuf.pull()
        yield fullBuf
      }
      if (!circbuf.isFullBufAvailable()) {
        let newDat = getNewBuffer(Blen, pza + 1)
        chai.expect(newDat).to.deep.equal(seq(pza + 1, pza + Blen), `getNewBuffer  incorrect ${newDat} expected ${seq(pza + 1, pza + Blen)}`)
        pza += newDat.length
      }
      // sleep(2000)
    }
  }

  // Main Processing loop for testing
  function* mainLoopFromBuildBuf(circbuf, maxIters) {
    for (let it = 0; it < maxIters; it++) {
      for (let buf of buildBuf(bufSize, circbuf, true))
        yield buf
    }
  }

  function run(circbuf, maxIters) {
    var loopx = 0
    for (let buf of mainLoopFromBuildBuf(circbuf, maxIters)) {
      chai.expect(buf).to.deep.equal(
        seq(loopx * Hop + 1, N + loopx * Hop), `Loop${loopx} incorrect fullBuf: ${buf} expected ${seq(loopx * Hop + 1, N + loopx * Hop)}`)
      if (buf == '' + seq(loopx * Hop + 1, N + loopx * Hop)) {
        console.log(`Loop${loopx} CORRECT fullBuf: ${buf}`)
      }
      loopx++
    }
  }

  let circbuf = new CircularBuffer(bufSize, nBufs, N, Hop, false, bufGenerator, consumeBuffer)
  run(circbuf, MaxIters)

}

describe('CircBuff ', function () {
  it('should return sequential array values', function () {
    circTest()
  });
});
