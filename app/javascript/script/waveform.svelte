<script>
    import { Waveform } from '../waveform/waveform';
    import { WaveformHelper } from '../waveform/waveform_helper';
    import Channel from '../waveform/channel/channel.svelte';
    import { audio_context_init } from '../audio/audio_context';
    import { loop_init } from '../audio/loop';
    import { play_callback, waveform_callback, create_audio_element_from_url, set_audio_to_channel } from '../audio/play';
    // import { get_audio_buffer, get_audio_buffer_info } from '../audio/buffer';
    import { times } from '../waveform/times'
    export let blob;
    let url = URL.createObjectURL(blob);
    let o = { meta: { id: '00'}, value: { docid: 'x' } };
    let waveform = new Waveform(o);
    let helper = new WaveformHelper(waveform);
    class Dummy {
        activate(){}
        set_times_then_draw(x, y){
            // this only needs to be called on one channel
            // ch1.set_times_then_draw(x, y);
        }
        update(){
            set_width();
            ch1.update();
        }
    }
    waveform.component = new Dummy();
    let ch1;
    let two = false;
    let active_channel = 0;
    function activate2(){}
    if(!window.ldc) window.ldc = {};
    if(!window.ldc.waveforms) window.ldc.waveforms = [];
    if(!window.ldc.resources) window.ldc.resources = {};
    window.ldc.wave_events_set = true;
    audio_context_init({});
    loop_init();
    window.ldc.vars.loop.set('play_callback', play_callback);
    window.ldc.vars.loop.set('waveform_callback', waveform_callback);
    window.ldc.resources.urls = { x: url };
    // let p = get_audio_buffer_info(url).then( (x) => waveform.audiof(x) );
    p.then( () => {
        waveform.wave_display_length = waveform.wave_audio.etime;
        let audio = helper.create_audio_hash_from_docid(o.value.docid);
        let audiok = helper.create_audiok_from_docid(o.value.docid);
        // get_audio_buffer(audio).then( (buffer) => {
        //     const w = waveform;
        //     const k = audiok;
        //     console.log(`SR ${buffer.sampleRate}`);
        //     w.wave_buffer_sample_rate = buffer.sampleRate;
        //     helper.sample_calculations();
        //     ch1.fill_cache(k, buffer);
        //     w.cache[k] = true;
        //     ch1.draw_buffer(k);
        // } );
    } );
    let div;
    // function set_width(){
    //     const w = waveform;
    //     times.update( (x) => {
    //         return {
    //             wave_display_offset: x.wave_display_offset,
    //             wave_display_length: x.wave_display_length,
    //             wave_canvas_width: div.offsetWidth
    //         }
    //     } );
    //     return;
    //     w.wave_canvas_width = div.offsetWidth;
    //     // w.wave_scale = w.wave_display_length / w.wave_canvas_width;
    //     helper.sample_calculations();
    // }
</script>

<style>
</style>

{#if url}
    {url}
    {#await p}
        waiting
    {:then}
        <div bind:this={div}>
            <Channel bind:this={ch1} {waveform} i={0} {two} active={active_channel == 0} on:active={activate2} />
        </div>
    {/await}
{:else}
    audio missing
{/if}
