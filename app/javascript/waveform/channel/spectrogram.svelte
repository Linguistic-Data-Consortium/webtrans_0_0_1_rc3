<script>
    import { tick } from 'svelte'
    import { onMount } from 'svelte';
    import { spectrogram_settings } from '../stores'
    import { fill_spectrogram_display_points } from './buffer'
    import Spinner from '../../work/spinner.svelte'
    export let waveform;
    // export let width;
    // export let height;
    let canvas;
    let ctx;
    let mounted = false;
    onMount( () => {
        mounted = true;
        // set_wh();
        ctx = canvas.getContext("2d");
        // if(spectrogram_open) tick().then( () => spectrogram.draw_buffer(scache[lastk]) );
    } );
    function set_wh(){
        canvas.width = waveform.wave_canvas_width;
        canvas.height = wave_canvas_height;
    }
    let points;
    export function draw_buffer(p){
        points = p;
        if(waveform.samples_per_pixel == null) return;
        // if(waveform.samples_per_pixel > samples_per_pixel_threshold){
        // ctx.clearRect(0, 0, canvas.width, canvas.height);
        working = true;
        setTimeout( () => draw(), 100 );
    }
    let working = false;
    function draw(){
        if(!mounted) return;
        if(!canvas) return; // why is this needed?
        set_wh();
        const spec = fill_spectrogram_display_points(
            waveform,
            points,
            fft_size,
            frame_time,
            time_step
        );
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const imageData = ctx.createImageData(canvas.width, canvas.height);
        const data = imageData.data;
        for(let i = 0; i < canvas.width; i++){
            let spec_i = spec[i];
            const i4 = i * 4;
            const cw4 = canvas.width * 4;
            const scale = canvas.height / spec_i.length;
            for(let ii = 0; ii < canvas.height; ii++){
                let data_i = ii * cw4 + i4;
                let iii = spec_i[Math.floor((canvas.height-1-ii)*scale)];
                data[data_i]     = iii;
                data[data_i + 1] = iii;
                data[data_i + 2] = iii;
                data[data_i + 3] = 255;
            }
        }
        ctx.putImageData(imageData, 0, 0);
        working = false;
    }
    let wave_canvas_height = 125;
    let fft_size = 128;
    let frame_time = 0.1;
    let time_step = 0.1;
    spectrogram_settings.subscribe( (x) => {
        if(x.height) wave_canvas_height = x.height;
        if(x.fft_size) fft_size = x.fft_size;
        // if(x.fft_size) wave_canvas_height = x.fft_size / 2;
        if(x.frame_time) frame_time = x.frame_time;
        if(x.time_step) time_step = x.time_step;
    });
</script>

<style>
</style>

{#if working}
    <div class="mx-auto w-16">
        <Spinner size="50" />
    </div>
{/if}
<canvas bind:this={canvas} />
