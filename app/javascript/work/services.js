import { getp, postp } from "./getp"
import { getSignedUrlPromise } from './aws_helper'
import { update_segments } from '../waveform/segments_helper'

function round_to_6_places(num) {
  return Math.round(num * 1000000) / 1000000;
}


const base = 'https://hlt.ldcresearch.org';
function get_promises(set_sp, set_op, o){
  let service_promise;
  let output_promise;
  let interval;
  const get_service_promise = (o) => {
    service_promise = postp(base + '/promises', o);
    set_sp(service_promise);
    service_promise.then( (o) => {
      interval = setInterval( () => get_output_promise(o), 1000);
    } );
  };
  const get_output_promise = (o) => {
    service_promise = getp(base + '/promises/' + o.id);
    set_sp(service_promise);
    service_promise.then( (o) => {
      if(o.status == 'resolved'){
        clearInterval(interval);
        output_promise = getp(o.data[0].output).then( (x) => JSON.parse(x) );
        set_op(output_promise);
        console.log('done');
      }
      else{
        console.log('waiting');
        console.log(o)
      }
    } );
  };
  get_service_promise(o);
}

function add_sad(){
  // w.keyboards.services.reset();
  // return
  // $.each window.ldc.resources.manifest.urls, (k, v) ->
  //     x = '1A9AMW16Zk7GaSoCg6VgXg1k'
  //     fn = "s3://image-description/#{x}"
  // fn = "s3://speechbiomarkers/LPWKgKHJGkR33HJupuRKnzeF"
  // fn = "https://speechbiomarkers.s3.amazonaws.com/LPWKgKHJGkR33HJupuRKnzeF?AWSAccessKeyId=AKIATXZECOV6D6NULGF3&Expires=1586911335&Signature=Ev3FpM%2FSkp3cS8ftyqU%2BZGPJvuc%3D"
  // $('.ChannelA').after('<div class="waiting">Waiting</div>');
  // a = [ [ 1.0, 2.0], [3.0, 4.0], [ 5.0, 6.0] ]
  // f2 a
  // return
  const urls = window.ldc.resources.urls;
  let k = Object.keys(urls)[0];
  if(k.match(/\.json$/)) k = k.replace(/json$/, 'wav');
  if(window.ldc.resources.bucket){
    const bucket = window.ldc.resources.bucket;
    let key = k; //.replace('10s.wav', '5s.wav')
    if(key.startsWith("s3://")){
      const idx = key.indexOf(bucket) + bucket.length + 1;
      key = key.substring(idx);
    }
    return getSignedUrlPromise(bucket, key);
  }
}
//     return getSignedUrlPromise(bucket, key).then(function(fn) {
//       // inputs: ["/NIEUW02/promises/sad_in/#{w.wave_docid}.wav"]
//       // inputs: ["/NIEUW02/Armstrong_moon_cut.wav"]
//       return ldc_services.sad(o, function(data) {
//         return add_timestamps(data);
//       });
//     });
//   }
// }


function check_channels(data) {
  const o = {
    ch1: [],
    ch2: []
  }
  // new format
  // or coincidentally old and short
  if(data.length === 1 || data.length === 2){
    o.ch1 = data[0];
    // check for old format
    if(o.ch1.length === 3 && typeof o.ch1[2] === 'string'){
      o.ch1 = data;
    }
    else if(data.length === 2){
      o.ch2 = data[1];
    }
  }
  else{
    o.ch1 = data;
  }
  o.ch1 = o.ch1.filter( x => x[2] == 'speech' );
  o.ch2 = o.ch2.filter( x => x[2] == 'speech' );
  return o;
}

function add_timestamps(o) {
  return () => {
    let t;
    let len2;
    for(t = 0, len2 = o.ch1.length; t < len2; t++){
      let x = o.ch1[t];
      let span = {
        offset: x[0],
        length: round_to_6_places(x[1] - x[0])
      };
      let docid = window.ldc.ns.waveform.docid.replace(/:B$/, ':A');
      window.ldc.ns.waveform.add_audio_to_list(docid, '.SegmentList', 'new.Segment', span);
    }
    let u;
    let len3;
    for(u = 0, len3 = o.ch2.length; u < len3; u++) {
      let x = o.ch2[u];
      let span = {
        offset: x[0],
        length: round_to_6_places(x[1] - x[0])
      };
      console.log(span);
      let docid = window.ldc.ns.waveform.docid.replace(/:A$/, ':B');
      window.ldc.ns.waveform.add_audio_to_list(docid, '.SegmentList', 'new.Segment', span);
    }
    ldc_annotate.submit_form();
    ldc_annotate.add_callback( () => update_segments() );
  }
}


export { get_promises, add_sad, check_channels, add_timestamps }
