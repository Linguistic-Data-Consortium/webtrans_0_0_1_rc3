<script>
    import { onMount } from 'svelte';
    export let waveform;
    // export let width;
    // export let height;
    export let line;
    export let max_only;
    export let skip;
    export let active;
    // export let i;
    export let wave_canvas_height;
    export let samples_per_pixel_threshold;
    // let points;
    // if(i) points = pointsb;
    // else  points = pointsa;
    let canvas;
    let ctx;
    function set_width(t){
        const w = waveform;
        canvas.width = t.wave_canvas_width;
        canvas.height = wave_canvas_height;
        // $("#{w.selector}-waveform-#{@i} svg").each (i, x) ->
        //     h = if i < 2 then w.wave_canvas_height else 20
        //     $(x).attr 'width', w.wave_canvas_width
        //     $(x).attr 'height', h
        
    }
    onMount( () => {
        set_width({ wave_canvas_width: 1000 });
        ctx = canvas.getContext("2d");
    } );
    let points;
    export function draw_buffer(p, t){
        const w = waveform;
        set_width(t);
        points = p;
        if(w.samples_per_pixel > samples_per_pixel_threshold){
            draw_waveform2(t);
        }
        else{
            draw_waveform3(t);
        }
    }
    function draw_waveform2(t){
        // that = this
        const w = waveform;
        // console.log 'wave' + ' ' + @i if @debug is true
        // active = @i is w.active_channel
        // if(disable_waveform){
        //     return;
        // }

        // return unless active is true
        // this adds a lot of time maybe 40 50 ms
        // if time
        //     this.draw_waveform_rect selector, wave_canvas_width, layer, 'white', time, 0, wave_canvas_width
        // console.log wave_audio

        // console.log "samples per pixel #{w.samples_per_pixel}" if w.debug

        // w = if selector.match(/1/) then waveform else waveform2
        // this.fill_waveform_display_points @i
        // console.log(@selector_waveform)
        // canvas = $(@selector_waveform)[0]
        // ctx = canvas.getContext "2d"
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.strokeStyle = 'black';
        ctx.lineWidth = 1;
        ctx.beginPath();
        const half_height = wave_canvas_height / 2;
        const quarter_height = half_height / 2;
        const three_quarters_height = half_height + quarter_height;
        // ctx.moveTo 0, half_height
        const scale =  t.wave_canvas_width / ( w.wave_buffer_sample_rate * t.wave_display_length );
        let midpoint;
        if(false && w.stereo){
            midpoint = quarter_height;
        }
        else{
            midpoint = half_height;
        }
        if(!line){
            // console.log "drawing to #{w.wave_canvas_width}"
            for(let i = 0; i <= t.wave_canvas_width; i += skip){
                let ii = i * 2;
                let mx = points[ii] * midpoint;
                // assume min/max symmetry for the moment
                let mn;
                if(max_only){
                    mn = mx * -1;
                }
                else{
                    mn = points[ii+1] * midpoint;
                }
                ctx.moveTo(i, midpoint + mn);
                ctx.lineTo(i, midpoint + mx);
                if(false && w.stereo){
                    // assume min/max symmetry for the moment
                    if(max_only){
                        mx = points[ii] * quarter_height;
                    }
                    ctx.moveTo(i, three_quarters_height - mx);
                    ctx.lineTo(i, three_quarters_height + mx);
                }
            }
        }
        // if display.line is false
        //     for i in [0..display.points.length-1]
        //         x = i / samples_per_pixel
        //         if display.max_only is true
        //             mx = display.points[i] * midpoint
        //         ctx.lineTo x, midpoint + mx
        ctx.stroke()
    }

    function draw_waveform3(t){
        // that = this
        const w = waveform;
        // console.log 'wave' + ' ' + @i if w.debug is true
        // active = @i is w.active_channel
        // if(disable_waveform){
        //     return;
        // }

        // return unless active is true
        // this adds a lot of time maybe 40 50 ms
        // if time
        //     this.draw_waveform_rect selector, wave_canvas_width, layer, 'white', time, 0, wave_canvas_width
        // console.log wave_audio

        // console.log "samples per pixel #{w.samples_per_pixel}" if w.debug
        const pixels_per_sample = 1 / w.samples_per_pixel;

        // w = if selector.match(/1/) then waveform else waveform2
        // this.fill_waveform_display_points channel
        // canvas = $(@selector_waveform)[0]
        // ctx = canvas.getContext "2d"
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.strokeStyle = 'black';
        ctx.lineWidth = 1;
        ctx.beginPath();
        const half_height = wave_canvas_height / 2;
        const quarter_height = half_height / 2;
        const three_quarters_height = half_height + quarter_height;
        // ctx.moveTo 0, half_height
        const scale =  t.wave_canvas_width / ( w.wave_buffer_sample_rate * t.wave_display_length );
        let midpoint;
        if(false && w.stereo){
            midpoint = quarter_height;
        }
        else{
            midpoint = half_height;
        }
        if(!line){
            // console.log "drawing to #{w.wave_canvas_width}"
            for(let i = 0; i <= points.length/2; i += 1){
                let ii = i*2;
                let mx = points[ii] * midpoint;
                ctx.lineTo(i*pixels_per_sample, midpoint + mx);
            }
        }
        ctx.stroke();
    }

    function draw_spectrogram(){
        return
        // if spectrogram_flag
        //     wave_display_offset_in_samples = w.convert_seconds_to_samples wave_display_offset
        //     step_seconds = 0.5
        //     step_samples = w.convert_seconds_to_samples step_seconds
        //     step_pixels  = w.convert_seconds_to_pixels  step_seconds
        //     frame_samples = 128
        //     frame_seconds = w.convert_samples_to_seconds frame_samples
        //     frame_pixels  = w.convert_seconds_to_pixels frame_seconds
        // 
        //     nframes = wave_display_length / step_seconds
        //     fft = new FFT(frame_samples, wave_buffer_sample_rate)
        //     signal = new Float32Array(frame_samples)
        // 
        //     waveform = "#spectrogram-canvas"
        //     layer = 'spec'
        //     $(waveform).removeLayerGroup(layer).drawLayers()
        //     $(waveform).draw
        //         layer: true
        //         groups: [ layer ]
        //         name: layer + '-1'
        //         fn: (ctx) ->
        //             for i in [0..nframes-1]
        //                 for j in [0..frame_samples-1]
        //                     signal[j] = wave_buffer_channel_data[i*step_samples+wave_display_offset_in_samples+j]
        //                 fft.forward signal
        //                 slength = fft.spectrum.length
        //                 vertical_step = wave_canvas_height / slength
        //                 for k in [0..slength-1]
        //                     ctx.fillStyle = "rgba(0, 0, 0, #{fft.spectrum[k]})"
        //                     ctx.fillRect i*step_pixels, wave_canvas_height-k*vertical_step, 10, 10
        //     # spectrum values appear to be between 0 and 1, but not sure
        //     if @debug
        //         console.log fft.spectrum.length
        //         console.log signal.length
        //         console.log step_pixels
    }
</script>

<style>
canvasx {
  position: absolute;
  top: 0;
  left: 0;
  background-color: transparent;
  z-index: 0;
  cursor: crosshair;
}
</style>

<canvas bind:this={canvas} class="waveform-waveform" class:active />
