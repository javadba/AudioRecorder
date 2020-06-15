
function seq(start,end) { return [...Array(end-start+1).keys()].map((x) => start+x) }

const stddev = function (data) { return new StatsHandler(data).stddev() };

const quantile = function (arr, q) { return new StatsHandler(arr).quantile(q) };

const stats = function(arr) { return new StatsHandler(arr).stats() }

let DisableAllPrinting = false

function p(msg) { if (!DisableAllPrinting) { console.log(msg) } }

class StatsHandler {

  constructor(name, maxSize = 500, skips = 10000) {
    this.name = name
    this.maxSize = maxSize
    this.skips = skips
    this.cntr = 0
    this.data = []
  }

  mean = (arr=this.data) => arr.reduce((acc, val) => acc + val, 0) / arr.length;

  stddev = function (data=this.data) {
    if (!data || data.length <= 1) {
      return 0
    } else {
      let m = this.mean(data);
      return Math.sqrt(data.reduce(function (sq, n) {
        return sq + Math.pow(n - m, 2);
      }, 0) / (data.length - 1));
    }
  };

  quantile(q, arr=this.data) {
    let sorted = [...arr]
    sorted.sort((a, b) => a - b)
    return sorted[Math.floor(q * (arr.length - 1))]
  }

  /** Use with care: keeps the largest values */
  quartileKeepLargest(arr, q) {
    let sorted = arr.sort( (a,b)=> a-b)
    return sorted[ Math.floor(q * (arr.length-1))]
  }

  stats(arr = this.data) {
    return {
      counter: this.cntr,
      bufSize: this.data.length,
      mean: this.mean(arr),
      stdev: this.stddev(arr),
      min: Math.min(...arr),
      max: Math.max(...arr),
      '1%': this.quantile( .01, arr),
      '10%': this.quantile( .1, arr),
      median: this.quantile( .5, arr),
      '90%': this.quantile( .9, arr),
      '99%': this.quantile( .99, arr)
    }
  }

  statsToString(arr=this.data) {
    return JSON.stringify(arr, null, 2)
  }

  toLogString() {
    return `[${Date.now()} ${this.name}-Stats ${this.cntr}] ${this.statsToString(this.stats())}`
  }

  print() {
    p(this.toLogString())
  }

  add(stat) {
    if (DefaultConf.enableStats) {
      if (this.data.length >= this.maxSize) {
        this.data.shift()
      }
      this.data.push(stat)
      this.cntr++
      if (this.cntr % this.skips == 1) {
        this.print()
      }
    }
  }
}

class Md5Manager {

  constructor(name, maxBufsCnt=256) {
    this.name = name
    this.MaxBufsCnt = maxBufsCnt
    this.bufs = []
    this.bufs2 = []
    this.stats = new StatsHandler(`${name}.`,500,10000)
  }

  printStats() {
    p(this.stats.toLogString())
  }

  printMd5(msg,mdd) {
    p(`Stats-${this.name} ${msg} ${mdd}`)
  }

  add(buf) {
    if (DefaultConf.enableMd5) {
      this.stats.add()
      let md55 = md5(buf)
      this.bufs.push(md55)
      if (this.bufs.length == this.MaxBufsCnt) {
        let md5b = md5(this.bufs.join(''))
        this.printMd5(`Level1'-${name}:`, md5b)
        this.bufs = []
        this.bufs2.push(md5b)
        if (this.bufs2.length == this.MaxBufsCnt) {
          let md5b = md5(this.bufs2.join(''))
          this.printMd5(`Level2'-${name}:`, md5b)
          this.bufs2 = []
        }
      }
    }
  }
}

function dcopy(x) {
	return JSON.parse(JSON.stringify(x))
}

function jprint(j) { p(JSON.stringify(j)) }

const l2Norm = function (data) {
    return Math.sqrt(data.reduce(function (sq, n) {
        return sq + Math.pow(n, 2);
    }, 0) / (data.length - 1));
};

function partition(arr,len) {
  return [...new Array(Math.ceil(arr.length / len))].map(_ => arr.splice(0, len))
}

function floatArrToArr(floatArr) {
  return [...Array(floatArr.length)].map(
    (x,i) => floatArr[i]
  )
}

function arrToFloatArr(arr) {
  let floatArr = new Float32Array(arr.length);
  [...arr].map( (x,i) => floatArr[i] = x)
  return floatArr
}


/** Multithreading not currently supported */
class PerfManager {
  constructor(name, maxSize=1000,printSkips=1000) {
    this.starts = {} // {str:str}
    this.stats = {} // {str:StatsHandler}
    this.maxSize = maxSize
    this.printSkips = printSkips
  }

  start(name) {
    this.starts[name] = Date.now()
  }
  stop(name) {
    if (DefaultConf.enablePerf) {
      if (this.stats[name] === undefined) {
        this.stats[name] = new StatsHandler(`perf.${name}`, this.maxSize, this.printSkips)
      }
      this.stats[name].add(Date.now() - this.starts[name])
    }
  }

  toString() {
    return `Perf-${this.name} ${this.stats.toLogString()}`
  }

}