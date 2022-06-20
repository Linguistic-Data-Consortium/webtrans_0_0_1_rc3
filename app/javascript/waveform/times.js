import { writable } from 'svelte/store'
const t = {
  wave_display_offset: 0,
  wave_display_length: 0,
  wave_canvas_width: 0
};
const times = writable(t);
const ssss = {
  wave_selection_offset: null,
  wave_selection_length: 0,
  wave_selection_end: null
};
const selection = writable(ssss);

const round_to_1_place = (num) => Math.round(num * 10) / 10;
const round_to_2_places = (num) => Math.round(num * 100) / 100;
const round_to_3_places = (num) => Math.round(num * 1000) / 1000;
const round_to_6_places = (num) => Math.round(num * 1000000) / 1000000;
function delay(w,x,y){
  setTimeout( () => {
    set_times(w,x,y);
  }, 1000);
}
function set_times(w, x, y){
  // if(!w.wave_buffer_sample_rate) delay(w,x,y);
  // const w = waveform;
  if(x < 0) x = 0;
  if(y > w.wave_audio.etime) y = w.wave_audio.etime;
  if(x + y > w.wave_audio.etime) x = w.wave_audio.etime - y;
  times.update( (t) => {
    t.wave_display_offset = x;
    t.wave_display_length = y;
    sample_calculations(w, x, y, t);
    return t;
  } );
  if(true) console.log(`update set wave display offset ${x} length ${y} and ${w.samples_per_pixel}`);
  // w.update_cursor = true;
  // w.update_scrollbar = true;
  // w.update_underlines = true;
  // w.update_play_head = true;
  // w.update_tick_times = true;
  // w.update_waveform = true;
  // this.draw_wave_display()
}
function sample_calculations(w, x, y, t){
  w.wave_scale = y / t.wave_canvas_width;
  if(!w.wave_buffer_sample_rate) return; // audio might not be loaded yet
  w.wave_display_length_in_samples = w.convert_seconds_to_samples(y);
  w.wave_display_offset_in_samples = w.convert_seconds_to_samples(x);
  w.samples_per_pixel = w.wave_display_length_in_samples / t.wave_canvas_width;
}

export {
  times,
  selection,
  round_to_1_place,
  round_to_2_places,
  round_to_3_places,
  round_to_6_places,
  set_times
}
