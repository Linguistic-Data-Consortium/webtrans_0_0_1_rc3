import { getp, postp, deletep, patchp, getp_wav } from "../work/getp";
import { ParseB } from '../waveform/parse_b';
import { set_urls } from '../waveform/aws_helper'
function wait_for_urls(f){
  if(window.ldc && window.ldc.resources && window.ldc.resources.urls){
    f();
  }
  else{
    setTimeout( function(){
      wait_for_urls(f);
    }, 100);
  }
}
let last_audio;
let last_buffer;
function get_audio_buffer_for_waveform(w, audio, t){
  let this_audio = [ audio.id.replace(/:[AB]$/, ''), audio.btime, audio.etime ].join(':');
  if(this_audio == last_audio){
    return Promise.resolve(last_buffer);
  }
  return get_audio_buffer(audio).then( (buffer) => {
    console.log(`SR ${buffer.sampleRate}`);
    w.wave_buffer_sample_rate = buffer.sampleRate;
    // helper.sample_calculations();
    w.wave_display_length_in_samples = w.convert_seconds_to_samples(t.wave_display_length);
    w.wave_display_offset_in_samples = w.convert_seconds_to_samples(t.wave_display_offset);
    w.samples_per_pixel = w.wave_display_length_in_samples / t.wave_canvas_width;
    last_audio = this_audio;
    last_buffer = buffer;
    return buffer;
  } );
}
function get_audio_buffer(audio){
  // # url = "/audio_files2?audio_id=#{audio.id}&beg=#{audio.btime}&end=#{audio.etime}"
  // # get url, (data) ->
  // #     audio_context.decodeAudioData(data).then (data) ->
  // #         data
  // # url = "#{bucket}#{audio.id}.wav"
  const unit = audio.block_size;
  // # unit = 1
  // sr = 16000
  // sr = 8000
  const sr = audio.sample_rate;
  const header_size = audio.header_size;
  const b = Math.floor(audio.btime * sr) * unit + header_size;
  const e = Math.floor(audio.etime * sr) * unit + header_size - 1;
  
  return new Promise( (resolve, reject) => {
    const urls = window.ldc.resources.urls;
    const k = (audio.uid || audio.id).replace(/:[AB]/,'');
    // return set_urls(k).then( (x) => {
      return getp_wav(urls[k], b, e).then( (data) => {
        const a = new Uint8Array(header_size + data.byteLength);
        console.log('HEAD');
        console.log(audio);
        a.set( new Uint8Array(audio.header), 0 );
        a.set( new Uint8Array(data), header_size );
        const f1 = (data) => resolve(data);
        window.ldc.vars.audio_context.decodeAudioData(a.buffer, f1);
        // # audio_context.decodeAudioData(a.buffer).then (data) ->
        // #     resolve(data)
      } );
    // } );
   } ) ;
}
function get_audio_buffer_info(k){
  // # url = "/audio_files2?audio_id=#{audio.id}&info=true"
  // # get url, (data) ->
  // #     data
  // # url = "#{bucket}#{audio.id}.wav"
  return new Promise( (resolve, reject) => {
    // ldc_nodes.wait_for_root_key_key( "resources", "urls", () => {
    set_urls(k).then( (x) => {
      const url = x.wav_url;
      // urls = $('.Root').data().resources.urls
      // const urls = window.ldc.resources.urls;
      // const url = urls[audio.uid || audio.id];
      // console.log(JSON.stringify(urls));
      // console.log(urls);
      // console.log(audio);
      getp_wav(url, 0, 8191).then( (header) => {
        // # url = "#{bucket}#{audio.id}.json"
        console.log("header ", header);
        // const url = urls[audio.uid || audio.id]
        console.log(url);
        const ret = {};
        const parser = new ParseB('name');
        ret.info = parser.parse(header);
        console.log(ret);
        getp_wav(url, 0, ret.info.dataOffset-1).then( (data) => {
          console.log("data2 ",  data);
          ret.header = data;
          resolve(ret);
        });
       } );
     } );
   } );
}
function get_audio_buffer_info_for_waveform(w){
  // set_urls(w.docid).then( (x) => {
    // const urls = window.ldc.resources.urls;
    w.bufferp = get_audio_buffer_info(w.docid)
      .then( (info) => audiof(info, w) );
  // } );
}
function audiof(data, w){
  const l = 10; // length in seconds
  const wh = 125; // height in pixels
  w.datainfo = data;
  w.header = data.header;
  w.header_size = data.info.dataOffset;
  if (data.info.channels > 1) {
    w.stereo = true;
  } else {
    w.stereo = false;
  }
  w.duration = data.info.duration || w.wave_audio.etime;
  w.sample_rate = data.info.sample_rate;
  w.block_size = data.info.blockSize;
  w.wave_audio.btime = 0;
  w.wave_audio.etime = w.duration;
  // w.set_width 0
  // w.set_width 1 if w.stereo
  // w.channels = [ { channel: 0 } ]
  // w.channels = [ ( new Channel w, 0 ) ]
  // w.channels.push ( new Channel w, 1 ) if w.stereo
  // for x in w.channels
  //     x.set_waveform_html()
  //     x.set_width()
  //     x.set_channel_display_properties()
  // $('.spectrogram-canvas').hide(); //unless that.spectrogram_flag
  // $('.waveform-scrollbar').css 'border', '1px solid black'

  // if w.stereo
  //     $("#{w.selector}-waveform-0 .waveform-ticks").remove()
  //     $("#{w.selector}-waveform-0 .waveform-scrollbar").remove()
  //     $("#{w.selector}-waveform-1 .selection-time-beg").remove()
  //     $("#{w.selector}-waveform-1 .selection-time-end").remove()
  //     # why is the following necessary?
  //     $("#{w.selector}-waveform-0").css 'height', wh
  //     $("#{w.selector}-waveform-1").css 'height', wh+40
  // else
  //     $("#{w.selector}-waveform-0").css 'height', wh+40
  // if ($(`${w.selector}-waveform-1`).length) {
  //   $(`${w.selector}-waveform-0`).css('height', wh);
  //   $(`${w.selector}-waveform-1`).css('height', wh + 40);
  // } else {
  //   $(`${w.selector}-waveform-0`).css('height', wh + 40);
  // }
  w.update_ticks = true;
  w.update_tick_times = true;
  w.update_underlines;
  // wave_buffer_sample_rate = b.sampleRate
  // buffer_length = b.length
  // that.set_time_heights t1, t2, 0
  // that.set_time_heights t1, t2, 1
  w.data_channels = data.channels;
  w.data_duration = data.duration;
  // z = y / w.wave_canvas_width
  // (.25 / 40) * w.wave_canvas_width = z
  w.set_times_then_draw(w.play_head, l);
}
export { get_audio_buffer_for_waveform, get_audio_buffer_info_for_waveform }
