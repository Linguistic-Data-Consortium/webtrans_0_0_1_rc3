<script>
    import { tick } from 'svelte'
    import Spectrogram from './spectrogram.svelte'
    import Frame from './frame.svelte'
    import Playhead from './playhead.svelte'
    import Waveform from './waveform.svelte'
    import Ticks from './ticks.svelte'
    import Scrollbar from './scrollbar.svelte'
    import Underlines from './underlines.svelte'
    import { fill_waveform_display_points } from './buffer'
    import { settings } from '../../class_defs/simple_transcription/stores'
    import { active_channel } from '../stores'
    import { times } from '../times'
    import { WaveformHelper } from '../waveform_helper';
    import { get_audio_buffer_for_waveform } from '../../audio/buffer';
    export let waveform;
    // export let i;
    export let i = 0;
    export let two;
    let helper = new WaveformHelper(waveform);
    let active;
    active_channel.subscribe( (x) => active = x == i );
    // let width;
    // let height;
    let points = [];
    // points = @points
    // for i in [0..w.wave_canvas_width]
    //     ii = i*2
    //     points[ii] = 0
    //     points[ii+1] = 0
    // x.wave_buffer_channel_data = data
    let line = false;
    let max_only = true;
    let skip = 1;
    let time_height_ticks = 0; // all times at top
    let time_height_cursor = 0; // tick times at top, cursor times at bottom
    let disable_waveform = false;
    let waveform_visible = true;
    // @selector = x.selector
    let wave_canvas_height = 125;
    let frame;
    let playhead;
    let scrollbar;
    let underlines;
    let ticks;
    // draws everything except the waveform
    // export function update(){
    //     const w = waveform;
    //     if(disable_waveform) return;
    //     // d1 = new Date() if w.debug
    //     // adds about 50ms
    //     if(w.update_cursor) frame.draw_svg();
    //     if(w.update_play_head) playhead.draw_play_head();
    //     if(w.update_scrollbar && scrollbar) scrollbar.draw_scrollbar();
    //     // if(w.update_underlines && underlines) underlines.update();
    //     if(w.update_ticks && ticks) ticks.draw_ticks();
    //     if(w.update_tick_times && ticks) ticks.draw_tick_times();
    //     // w.draw_waveform() if w.update_waveform
    //     // if w.debug is true
    //     //     d2 = new Date()
    //     //     console.log "update waveform canvas: took #{d2.getTime() - d1.getTime()} ms, at scale of #{w.wave_scale*1000} ms, with tick step of #{@step} seconds"
    // }
    const cache = {};
    const scache = {};
    const cache2 = {};
    const samples_per_pixel_threshold = 200; // for deciding whether to draw an envelope or a graph
    function fill_cache(k, buffer, t){
        const w = waveform;
        let b = w.samples_per_pixel > samples_per_pixel_threshold;
        let x = fill_waveform_display_points(buffer, waveform, wave_canvas_height, i, !b, skip, t);
        cache[k] = x[0];
        scache[k] = x[1];
    }
    let ww;
    let lastk;
    function draw_buffer(k, t){
        lastk = k;
        if(disable_waveform) return;
        ww.draw_buffer(cache[k], t);
        if(spectrogram_open) spectrogram.draw_buffer(scache[k], t);
    }
    let spectrogram;
    let spectrogram_open;
    settings.subscribe( (x) => {
        if(x.key != 'settings') return;
        console.log('settings')
        console.log(x);
        // if(x.wave_canvas_height) wave_canvas_height = x.wave_canvas_height;
        // tick().then( () => spectrogram.draw_buffer(cache[lastk]) );
        spectrogram_open = x.spectrogram_open;
        if(spectrogram_open) tick().then( () => spectrogram.draw_buffer(scache[lastk]) );
    })
    function create_audio(docid){
        return helper.create_audio_hash_from_docid(docid, wave_display_offset, wave_display_length);
    }
    function create_audiok(docid){
        return helper.create_audiok_from_docid(docid, wave_display_offset, wave_display_length);
    }
    function draw_waveform(t){
        const w = waveform;
        let audio;
        let k;
        if(i == 0){
            audio = create_audio(w.wave_docid);
            k = create_audiok(w.wave_docid);
        }
        else{
            let docid2 = w.wave_docid.replace(/_A/g, '_B').replace(':A', ':B');
            audio = create_audio(docid2);
            k = create_audiok(docid2);
        }
        // if(!w.wave_buffer_sample_rate) return;
        // clear_buffer()
        // if(w.wave_docid.match(/^s3:/)) return;
        if(cache2[k]){
            console.log(`cache hit ${k}`);
            if(k != w.last_drawn){
                draw_buffer(k, t);
                // if(two){
                //     const docid2 = w.wave_docid.replace(/_A/g, '_B').replace(':A', ':B');
                //     draw_buffer(create_audiok(docid2), 'B', t);
                // }
            }
        }
        else{
            console.log(cache2);
            cache2[k] = true;
            get_audio_buffer_helper(k, audio, t);
            // if(w.wave_docid.match(/_A.wav$/)){
                // two = true;
            // if(two){
            //     w.update_cursor = true;
            //     // w.update_scrollbar = true;
            //     // w.update_underlines = true;
            //     w.update_play_head = true;
            //     // w.update_ticks = true;
            //     // w.update_tick_times = true;
            // 
            //     const docid2 = w.wave_docid.replace(/_A/g, '_B').replace(':A', ':B');
            //     get_audio_buffer_helper(create_audiok(docid2), create_audio(docid2), 'B', t);
            // }
        }
        w.last_drawn = k;
    }
    function get_audio_buffer_helper(k, audio, t){
        const w = waveform;
        get_audio_buffer_for_waveform(w, audio, t).then( (buffer) => {
            fill_cache(k, buffer, t);
            // w.cache[k] = true;
            draw_buffer(k, t);
        } );
    }
    let wave_display_offset;
    let wave_display_length;
    times.subscribe( (x) => {
        wave_display_offset = x.wave_display_offset;
        wave_display_length = x.wave_display_length;
        if(wave_display_length) draw_waveform(x);
    } );
</script>

<style>
    .container {
        position: relative;
        height: 185px;
    }
</style>

<!-- <canvas class="spectrogram-canvas" /> -->
<!-- <canvas class='waveform-canvas',    '' ]
<canvas class='waveform-play-head',  '' ] -->
{#if spectrogram_open}
    <Spectrogram
        bind:this={spectrogram}
        {waveform}
    />
{/if}
<div class="relative">
 <!-- style="height: {waveform.wave_canvas_height}px"> -->
<Frame
    bind:this={frame}
    {waveform}
    {i}
    {time_height_cursor}
    {active}
    {wave_canvas_height}
/>
<div class="absolute top-0">
<Playhead
    bind:this={playhead}
    {waveform}
    {time_height_cursor}
    {active}
    {wave_canvas_height}
/>
</div>
<div class="absolute top-0">
<Waveform
    bind:this={ww}
    {waveform}
    {line}
    {max_only}
    {skip}
    {active}
    {wave_canvas_height}
    {samples_per_pixel_threshold}
/>
</div>
 <!-- <svg"'", "'"xmlns"'", "http://www.w3.org/2000/svg", "'"viewBox"'", "0 0 30 20", "'""'" ] -->
{#if i == 1 || !two}
    <Ticks
        bind:this={ticks}
        {waveform}
        height=20
    />
    <Scrollbar
        bind:this={scrollbar}
        {waveform}
        height=20
    />
{/if}
    <Underlines
        bind:this={underlines}
        {waveform}
        {i}
        height=20
    />
</div>
