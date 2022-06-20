import { srcs } from '../work/sources_stores'
import { round_to_3_places } from './times'
class WaveformHelper {
  constructor(waveform){
    this.waveform = waveform;
  }
  find_segment(){
      const w = this.waveform;
      for( let [ k, v ] of w.set_playing_transcript_line_index){
          let e = v[0];
          let segment = v[1];
          if(k <= w.play_head && e >= w.play_head) return segment;
      }
  }
  find_segment2(){
      const w = this.waveform;
      const index = w.set_playing_transcript_line_index;
      let found = 0;
      // console.log "INDEX"
      // console.log index
      for( let [ k, v ] of index ){
          let e = v[0];
          let segment = v[1];
          if(w.play_head < k){
              break;
          }
          else{
              if(k <= w.play_head && e >= w.play_head){
                  found = null;
                  break;
              }
              if(e <= w.play_head){
                  found = segment;
                  found = e;
              }
          }
      }
      return found;
  }
  // sample_calculations(){
  //   const w = this.waveform;
  //   w.wave_scale = w.wave_display_length / w.wave_canvas_width;
  //   if(!w.wave_buffer_sample_rate) return; // audio might not be loaded yet
  //   w.wave_display_length_in_samples = w.convert_seconds_to_samples(w.wave_display_length);
  //   w.wave_display_offset_in_samples = w.convert_seconds_to_samples(w.wave_display_offset);
  //   w.samples_per_pixel = w.wave_display_length_in_samples / w.wave_canvas_width;
  // }
  // set_times_then_draw(x, y){
  //   const w = this.waveform;
  //   if(x < 0) x = 0;
  //   if(y > w.wave_audio.etime) y = w.wave_audio.etime;
  //   if(x + y > w.wave_audio.etime) x = w.wave_audio.etime - y;
  //   w.wave_display_offset = x;
  //   w.wave_display_length = y;
  //   this.sample_calculations();
  //   if(true) console.log(`update set wave display offset ${x} length ${y} and ${w.samples_per_pixel}`);
  //   w.update_cursor = true;
  //   w.update_scrollbar = true;
  //   // w.update_underlines = true;
  //   srcs.update( x => x );
  //   w.update_play_head = true;
  //   w.update_tick_times = true;
  //   w.update_waveform = true;
  //   // this.draw_wave_display()
  // }
  create_audio_hash_from_docid(docid, wave_display_offset, wave_display_length){
    const w = this.waveform;
    return {
      id: docid,
      btime: round_to_3_places(wave_display_offset),
      etime: round_to_3_places(wave_display_offset + wave_display_length),
      header: w.header,
      header_size: w.header_size,
      sample_rate: w.sample_rate,
      block_size: w.block_size
    };
  }
  create_audiok_from_docid(docid, wave_display_offset, wave_display_length){
    const w = this.waveform;
    const audiok = {
      id: docid,
      btime: round_to_3_places(wave_display_offset),
      etime: round_to_3_places(wave_display_offset + wave_display_length)
    };
    // w.get_audio_buffer(audio).then (buffer) ->
    //     w.component.draw_buffer buffer
    return JSON.stringify(audiok);
  }

  add_audio_to_list(docid, list_selector, audio_path, span){
    console.log(span);
    if (span.length === 0) {
      // this doesn't always make sense
      return alert('select a region first');
    } else {
      if (this.debug) {
        console.log('list');
        console.log(list_selector);
      }
      ldc_annotate.add_message($(list_selector).data().meta.id, 'add', null);
      // w = if w.active_channel is 0 then waveform else waveform2
      const etime = span.offset + span.length;
      const src = {
        docid: docid,
        beg: round_to_3_places(span.offset),
        end: round_to_3_places(etime)
      };
      src.play_head = src.beg;
      if (true) { //@debug
        console.log('adding line');
        console.log(src);
      }
      ldc_annotate.add_message(audio_path, 'change', src);
      if (span.transcript) {
        ldc_annotate.add_message('new.Transcription', 'change', {
          value: span.transcript
        });
      }
      if (span.speaker) {
        ldc_annotate.add_message('new.Speaker', 'change', {
          value: span.speaker
        });
      } else {
        // data = $('.Speaker').data();
        // if (data) {
          const speaker = window.ldc.vars.last_speaker_used;
          if (speaker) {
            ldc_annotate.add_message('new.Speaker', 'change', {
              value: speaker
            });
          }
        // }
      }
      return 'submit';
    }
  }

}

export { WaveformHelper }
