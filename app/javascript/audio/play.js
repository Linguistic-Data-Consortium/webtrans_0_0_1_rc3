let debug = true;
let playing = false;
let currently_playing_start_time = 0;
let currently_playing_stop_time = 0;
let currently_playing_offset = 0;
let current_audio_node;
let overplay;
let currently_playing_audio;
let currently_playing_source;
const round_to_3_places = (num) => Math.round( num * 1000 ) / 1000;
let custom_play_callback;
const map_stereo = new Map();
function is_playing(){ return playing; }
function play_callback(t){
  if(!playing) return;
  const now = window.ldc.vars.audio_context.currentTime - currently_playing_start_time + currently_playing_offset;
  if(now < currently_playing_stop_time){
    // console.log "Now #{now}" if debug
    if(current_audio_node) current_audio_node.play_head = round_to_3_places(now);
    // # requestAnimationFrame play_callback if playing
  }
  else{
    if(current_audio_node) current_audio_node.play_head = round_to_3_places(currently_playing_stop_time);
    overplay = currently_playing_stop_time;
    stop_playing();
  }
  // # called continuously via requestAnimationFrame in ldc_source
  // # if current_audio_node and current_audio_node.waveform
  // #     current_audio_node.waveform.play_callback current_audio_node, playing
  if(custom_play_callback) custom_play_callback(current_audio_node, playing);
  // # analyzer.getFloatFrequencyData(freqDomain)
  // # waveform = "#spectrogram-canvas"
  // # layer = 'spec'
  // # $(waveform).removeLayerGroup(layer).drawLayers()
  // # $(waveform).draw
  // #     layer: true
  // #     groups: [ layer ]
  // #     name: layer + '-1'
  // #     fn: (ctx) ->
  // #         for i in [0..analyzer.frequencyBinCount] by 10
  // #             xx = Math.abs(freqDomain[i])
  // #             ii = i / 1024 * wave_canvas_height
  // #             ctx.fillStyle = 'blue'
  // #             ctx.fillRect x, ii, 1, 1
}
function waveform_callback(){
  for(let w of window.ldc.waveforms)
    w.waveform_callback(current_audio_node, playing);
}
function play_src_with_audio(audio, src, f){
  // if debug is true
  //     console.log 'tryin to play'
  //     console.log node
  // # was_playing = playing
  stop_playing();
  // # stop_callback current_audio_node if was_playing is true
  current_audio_node = audio;
  // # the following line is triggered elsewhere
  // # this.set_active_transcript_line $(node).parents(transcript_line_selector)[0]
  // # console.log wave_buffers
  show_and_play_src2(src, null, f);
}
function show_and_play_src2(src, beg, f, g){
  // if debug is true
  //     console.log 'update show and play src'
  play_src2(src, f, g);
  // show_src2(src, beg);
}
function play_src2(src, f){
  play_this_span2(src, f);
}
function play_this_span2(src, f){
  console.log(current_audio_node);
  // $("#node-#{current_audio_node.meta.id}").data().audio.then (b) ->
  current_audio_node.audio.then( (b) => {
    src.docid = current_audio_node.docid;
    if(b instanceof Audio)
        play_audio_object(b, src, f);
    // else
    //     that.play_this_span3(src, custom_play_callback, b)
  } );
}
async function play_audio_object(audio, src, f){
  // # debug = true
  if(playing) return;
  if( audio.readyState < 2 || audio.seekable.end(0) == 0 ){
      audio.load();
      console.log('loading');
      await new Promise( (r) => audio.addEventListener('canplay' , r) );
  }
  if(debug) console.log(src);
  const poffset = round_to_3_places(src.beg);
  const plength = round_to_3_places(src.end - src.beg);
  // # plength = 1
  // # ppoffset = 0 # poffset
  const audio_context = window.ldc.vars.audio_context;
  if(audio_context.state == 'suspended') audio_context.resume();
  // if true #debug
  //     console.log "play #{poffset} #{plength}"
  //     console.log typeof(poffset)
  //     console.log typeof(plength)
  console.log(`ready ${audio.readyState}`);
  audio.currentTime = poffset;
  console.log(audio.currentTime);
  console.log(audio.duration);
  currently_playing_stop_time = poffset + plength;
  currently_playing_offset = poffset;
  if(current_audio_node){
    current_audio_node.play_head = currently_playing_offset;
    // const value = current_audio_node.value.value;
    // if(value && value.match(/^\d+$/))
    //   current_audio_node.value.value = `${parseInt(value)+1}`;
  }

  custom_play_callback = f;

  // # freqDomain = new Float32Array(analyzer.frequencyBinCount)

  audio.play().then( () => {
    currently_playing_start_time = audio_context.currentTime;
    playing = true;
    currently_playing_audio = audio;
    // that.write_to_hud audio
  } );
}
function stop_playing(){
  if(currently_playing_source){
    if(currently_playing_source.stop)
      currently_playing_source.stop(0);
    else
      currently_playing_source.noteOff(0);
    currently_playing_source = null;
  }
  else if(currently_playing_audio){
    currently_playing_audio.pause();
    // that.write_to_hud currently_playing_audio
    currently_playing_audio = null;
  }
  playing = false;
  // # $('.icon-play').show()
  // # $('.icon-pause').hide()
}
function create_audio_element_from_url(url, w){
  const parent = new Audio(url);
  parent.crossOrigin = 'anonymous';
  map_stereo.set(parent, {
      source: undefined,
      channel: 0
  });
  parent.addEventListener('play', async () => {
    if (!w.stereo) return true;
    const audioCtx = window.ldc.vars.audio_context;

    const attr = map_stereo.get(parent);
    if (attr.source===undefined)
      attr.source = audioCtx.createMediaElementSource(parent);

    const count = attr.source.channelCount;
    if (attr.channel<0 || attr.channel>=count)
    return attr.source.connect(audioCtx.destination);

    const splitter = audioCtx.createChannelSplitter(count);
    const merger = audioCtx.createChannelMerger(count);

    const clear = ()=>{
      splitter.disconnect();
      merger.disconnect();
    }
    parent.addEventListener('end', clear);
    parent.addEventListener('pause', clear);

    attr.source.connect(splitter);

    for (let i = 0; i<count; i++)
      splitter.connect(merger,attr.channel,i);

    merger.connect(audioCtx.destination);
  });
  return parent;
}
// # console.log 'AUDIO'
// # console.log parent
// # console.log parent.stereo
// # parent_source = audio_context.createMediaElementSource parent
// # analyzer = audio_context.createAnalyser()
// if false #src.stereo is true
//     splitter = audio_context.createChannelSplitter(2)
//     xcurrently_playing_source.connect(splitter)
//     splitter.connect(analyzer, active_channel)
// else
//     # parent_source.connect(analyzer)
// # analyzer.connect(audio_context.destination)
function set_audio_to_channel(v, channel){
  // return;
  const f = (audio) => {
    const attr = map_stereo.get(audio);
    if (attr) attr.channel = channel;
  };
  // Object.values(audio_elements)[0].then(f);
  v.then(f);
}
export {
  is_playing,
  play_callback,
  waveform_callback,
  play_src_with_audio,
  stop_playing,
  create_audio_element_from_url,
  set_audio_to_channel
}
