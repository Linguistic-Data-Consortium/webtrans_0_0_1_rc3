import { ParseB } from '../waveform/parse_b';

// returns a MediaStream object
function getUserMedia(){
  return navigator.mediaDevices.getUserMedia({audio: true, video: false})
}

function create_blob(chunks){
  let size = 0;
  for(let x of chunks){
    size += x.length;
  }
  size *= 2;
  // console.log 'length'
  // console.log that.recorded_chunks.length
  // console.log that.time_domain_chunks.length
  // console.log that.recorded_chunks
  // console.log that.time_domain_chunks

  // # recordedChunks = that.recorded_chunks
  // # window.blob = new Blob(that.recordedChunks)#, { 'type': 'audio/wav' })

  const parser = new ParseB('name');
  const sampleRate = window.ldc.vars.audio_context.sampleRate;
  const view = parser.create_view(size, sampleRate);

  // # samples are reals in [-1, 1]
  // # create 16 bit signed integers by setting range
  // # conversion is sample * range
  let range = 0x7FFF;

  let scale = false;

  // # scale values up to make use of the range
  if(scale){
    // # find maximum sample magnitude
    let max = 0;
    for(let chunk of chunks){
      for(let sample of chunk){
        let v = Math.abs(sample);
        if(v > max) max = v;
      }
    }
    // # scale the range to scale the samples
    // # use .99 to avoid clipping
    if(max < .99) range *= .99 / max;
  }

  // # convert samples and insert into file
  let index = 44; // # wav header length
  for(let chunk of chunks){
    let sum = 0;
    for(let sample of chunk){
      sum += sample * sample;
      view.setInt16(index, sample * range, true);
      index += 2;
    }
    // let rms = Math.sqrt(sum / chunk.length);
    // that.recorded_chunks_rms.push rms
  }

  // # that.rms_stats()
  let blob = new Blob([view], {type: 'audio/wav'});
  // # console.log that.recorded_chunks
  // that.recordedChunks = []
  return blob;
}
function filename_from_date(){
  return new Date().toISOString().replace(/[-:]/g,'').replace(/\.\d*/,'');
}
// set up streaming and optionally recording
// args:
// stream: MediaStream object, probably created by getUserMedia above
// record: boolean. true means save the audio via 
function create_analyzer(stream, record, onstopf, analyzef){
  const chunks = [];
  const ac = window.ldc.vars.audio_context;
  console.log(ac);
  const source = ac.createMediaStreamSource(stream);
  // # Create a new volume meter and connect it.
  // # that.meter = createAudioMeter(ac, 1, .1)
  // # console.log(that.meter.checkClipping())
  const analyzer = ac.createAnalyser();
  source.connect(analyzer);
  const processor_node = ac.createScriptProcessor(4096);
  analyzer.connect(processor_node);
  processor_node.connect(ac.destination);
  let mediaRecorder;
  if(record){
    processor_node.onaudioprocess = (e) => chunks.push( new Float32Array(e.inputBuffer.getChannelData(0)) );
    // const opts = {};
    // mediaRecorder = new MediaRecorder(stream, opts);
    // mediaRecorder.onstop = onstopf;
    // mediaRecorder.start();
  }
  const o = {
    analyze: create_analyzef(analyzer, analyzef),
    destroy: create_destroyf(mediaRecorder, stream, processor_node),
    chunks: chunks
  };
  return o;
}
function create_analyzef(analyzer, f){
  const time_domain = new Float32Array(analyzer.fftSize);
  const freq_domain = new Float32Array(analyzer.frequencyBinCount);
  return () => {
    if(!analyzer.getFloatTimeDomainData) return;
    analyzer.getFloatTimeDomainData(time_domain);
    analyzer.getFloatFrequencyData(freq_domain);
    f(time_domain, freq_domain);
  };
}
function create_destroyf(mediaRecorder, stream, processor_node){
  return () => {
    // #     that.stop_watch_stop()
    if(mediaRecorder){
      mediaRecorder.stop();
      for(let t of stream.getAudioTracks()){
        t.stop();
      }
    }

    // # that.meter.shutdown()
    processor_node.disconnect();
    processor_node.onaudioprocess = null;
  }
}

export { getUserMedia, create_blob, filename_from_date, create_analyzer }
