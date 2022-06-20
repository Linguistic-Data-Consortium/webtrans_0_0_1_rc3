function fill_waveform_display_points(buffer, w, wave_canvas_height, i, line, skip, t){
  // that = this
  // wave_display_length_in_samples = w.convert_seconds_to_samples w.wave_display_length
  // wave_display_offset_in_samples = w.convert_seconds_to_samples w.wave_display_offset
  // samples_per_pixel = wave_display_length_in_samples / w.wave_canvas_width
  const half_height = wave_canvas_height / 2;
  const pixels_per_sample = 1 / w.samples_per_pixel;
  const ii = w.stereo ? i : 0;
  const wave_buffer_channel_data = buffer.getChannelData(ii);
  const points = [];
  if(line){
    for(let i = 0; i < wave_buffer_channel_data.length; i += 1){
      let ii = i*2;
      points[ii] = wave_buffer_channel_data[i];
      points[ii+1] = 0;
    }
  }
  else{
    for(let i = 0; i <= t.wave_canvas_width; i += skip){
      let ii = i*2;
      // wave_buffer_channel_data_i = Math.floor(i*samples_per_pixel+wave_display_offset_in_samples)
      let wave_buffer_channel_data_i = Math.floor(i*w.samples_per_pixel);
      // x = wave_buffer_channel_data[wave_buffer_channel_data_i]
      let mx = 0;
      let mn = 0;
      for(let iii = 0; iii < w.samples_per_pixel; iii += 1){
        let xx = wave_buffer_channel_data[wave_buffer_channel_data_i+iii];
        if(xx > mx) mx = xx;
        if(xx < mn) mn = xx;
      }
      // points[ii] = if mx > Math.abs(mn) then mx else mn
      points[ii] = mx;
      points[ii+1] = mn;
      // if display.max_only is true
      //     display.points[ii+1] = x
      // if(false && w.stereo == true){
      //     x = wave_buffer_channel_data2[wave_buffer_channel_data_i]
      //     waveform_display.points2[ii] = x
      //     if waveform_display.max_only is true
      //         waveform_display.points2[ii+1] = x
    }
  }
  scale_points(points);
  return [ points, wave_buffer_channel_data ];
}

function scale_points(points){
  let mx = 0;
  let mn = 0;
  // let mx = Math.max(...points);
  // let mn = Math.min(...points);
  for(let i = 0; i < points.length; i++){
    if(points[i] > mx) mx = points[i];
    mn = Math.abs(points[i]);
    if(mn > mx) mx = mn;
  }
  for(let i = 0; i < points.length; i++ ) points[i] /= mx;
}

function fill_spectrogram_display_points(
  w,
  wave_buffer_channel_data,
  fft_size,
  seconds_per_frame,
  seconds_per_step
){
  // set some constants for readability
  const total_seconds = w.wave_display_length;
  const total_pixels = w.wave_canvas_width;
  const seconds_per_pixel = w.wave_scale;
  const sample_rate = w.wave_buffer_sample_rate;
  // don't let step be smaller than a pixel
  if(seconds_per_step < seconds_per_pixel) seconds_per_step = seconds_per_pixel;
  const fft_size_half = fft_size / 2;
  const samples_per_frame = seconds_per_frame * sample_rate;
  const samples_per_step = seconds_per_step * sample_rate;
  const fft = new FFT(fft_size, sample_rate);
  const apply_window_function = new WindowFunction(DSP.GAUSS);
  const preemphasis = new Float64Array(fft_size_half);
  // from matlab: preemph = 6 .* log2.((1:Nover2) ./ Nover2 .* (samp_rate/2) ./1000) .+ 6
  for(let i = 0; i < fft_size_half; i++) preemphasis[i] = 6 * Math.log10(sample_rate/2/1000*(i/fft_size_half)) + 6;
  preemphasis[0] = preemphasis[1]; // first value might be problematic
  const spectrogram = [];
  const zeros = [];
  for(let i = 0; i < fft_size_half; i++) zeros[i] = 255; // white pixels
  for(let i = 0; i <= total_pixels; i++) spectrogram[i] = zeros;
  // iterate over frames
  let n = Math.floor((total_seconds - seconds_per_frame) / seconds_per_step);
  let allmax = null;
  let allmin = null;
  for(let i = 0; i < n; i++){
    let wave_buffer_channel_data_i = Math.floor(i*samples_per_step);
    let frame = new Float64Array(samples_per_frame);
    for(let i = 0; i < samples_per_frame; i++) frame[i] = wave_buffer_channel_data[wave_buffer_channel_data_i+i];
    apply_window_function.process(frame);
    let padded_frame = new Float64Array(fft_size);
    for(let i = 0; i < samples_per_frame; i++) padded_frame[i] = frame[i];
    for(let i = samples_per_frame; i < fft_size; i++) padded_frame[i] = 0;
    fft.forward(padded_frame);
    // array of dB values
    let spectrum = new Float64Array(fft_size_half);
    // fft.spectrum already in terms of magnitudes
    for(let i = 0; i < fft_size_half; i++){
      spectrum[i] = 20 * Math.log10(fft.spectrum[i]); // - preemphasis[i];
      let s = 20 * Math.log10(sample_rate/fft_size_half*Math.abs(fft.spectrum[i])) + preemphasis[i];
      spectrum[i] = s;
      // spectrum[i] = preemphasis[i];
      // spectrum[i*2+1] = spectrum[i*2];
      if(allmax == null || s > allmax) allmax = s;
      if(allmin == null || s < allmin) allmin = s;
    }
    // for(let i = 0; i < fft_size_half; i ++){
    //   // if(spectrum[i] < 0) spectrum[i] = 0;
    //   if(spectrum[i] > allmax) allmax = spectrum[i];
    // }
    let xx = Math.max(...spectrum);
    let yy = Math.min(...spectrum);
    // console.log(preemphasis)
    // console.log(frame)

    for(let i = 1; i < 10; i++){
      spectrum[Math.floor(fft_size_half/sample_rate*i*1000*2)] = 0;
      // spectrum[Math.floor(fft_size_half/sample_rate*i*1000)*2+1] = 0;
    }
    // x and y are the end points of the analysis window
    let x = (i - .5) * seconds_per_step + seconds_per_frame / 2;
    let y = x + seconds_per_step;
    x = Math.floor(x / seconds_per_pixel);
    y = Math.floor(y / seconds_per_pixel);
    for(let i = x; i < y; i++){
      if(i > 0 && i < spectrogram.length) spectrogram[i] = spectrum;
    }
  }
  let dr = allmin - allmax;
  let dynamic_range = 50;
  if(dynamic_range) dr = -dynamic_range;
  let scale = 255 / dr;
  for(let ii = 0; ii < spectrogram.length; ii++){
    // make copies of the spectra because there's some repetition in the previous loop
    let spectrum = new Float64Array(fft_size_half);
    spectrum.set(spectrogram[ii]);
    spectrogram[ii] = spectrum;
    for(let i = 0; i < fft_size_half; i++){
      spectrum[i] -= allmax;
      if(spectrum[i] < dr) spectrum[i] = dr;
      spectrum[i] *= scale;
    }
  }
  // console.log(preemphasis)
  return spectrogram;
}

export { fill_waveform_display_points, fill_spectrogram_display_points }
