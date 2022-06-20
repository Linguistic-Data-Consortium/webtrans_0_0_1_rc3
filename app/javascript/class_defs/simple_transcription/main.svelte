<script>
    import { onDestroy } from 'svelte'
    import { audio_context_init } from '../../audio/audio_context';
    import { loop_init } from '../../audio/loop';
    import WaveformC from '../../waveform/waveform.svelte'
    import Transcript from '../../waveform/transcript.svelte'
    import Undo from '../../work/undo.svelte'
    import CreateTranscript from '../../waveform/create_transcript.svelte';
    import Settings from './settings.svelte'
    import { settings } from './stores'
    import { getp } from '../../work/getp'
    import Modal from '../../modal.svelte'
    import { btn } from '../../work/buttons'
    import { active_docid } from '../../waveform/stores'
    import { Waveform } from '../../waveform/waveform'
    import { set_urls } from '../../waveform/aws_helper'
    export let data_set_id;
    export let kit_id;
    export let source_uid;
    let waveform = new Waveform(window.ldc.ns);
    window.ldc.ns.waveform = waveform;
    waveform.docid = source_uid;
    if(waveform.docid.match(/_A\.wav/)) waveform.docid2 = waveform.docid.replace(/_A/g, '_B');
    waveform.wave_audio.id = source_uid;
    waveform.wave_docid = source_uid;
    let w;
    let t;
    export function update(){                  w.update() }
    // export function fill_cache(k, buffer, ch){ w.fill_cache(k, buffer, ch) }
    // export function draw_buffer(k, ch){        w.draw_buffer(k, ch) }
    export function show_help_screen_main(x){  w.show_help_screen_main(x) }
    export function upload_transcript(){       w.upload_transcript() }

    export function play_src(src, f){ w.play_src(src, f); }
    
    export function play_current_span_or_play_stop(){ w.play_current_span_or_play_stop(); }
    export function play_current_span(){ w.play_current_span(); }
    export function stop_playing(){ w.stopplaying(); }
    export function play_from_cursor(){ w.play_from_cursor(); }
    export function play_from_selection_beg(){ w.play_from_selection_beg(); }
    export function play_from_selection_end(){ w.play_from_selection_end(); }

    export function get_active(){
        return t.get_active();
    }
    export function set_active_transcript_line(id, dont_focus){
        return t.set_active_transcript_line(id, dont_focus);
    }
    export function refocus(){ t.refocus(); }
    export function find_active_id(){
        return t.find_active_id();
    }
    export function set_active_transcript_line_to_next(){
        return t.set_active_transcript_line_to_next();
    }
    export function set_active_transcript_line_to_prev(){
        return t.set_active_transcript_line_to_prev();
    }
    export function draw_waveform() { w.draw_waveform() }
    let u;
    export function undo(){ u.undo() }
    export function refresh() { t.refresh() }
    function wait(data){
        if(data.first == true){
            first = true;
            let e = document.getElementById('main');
            e.innerHTML = '<h3>creating transcript...</h3>'
        }
        if(data.wait){
            let e = document.getElementById('main');
            e.innerHTML += '<div>working...</div>';
            console.log("waiting");
            setTimeout( () => check(true), 1000);
        }
        else{
            console.log(data);
            if(first) setTimeout( () => window.location.reload(), 2000);
        }
    }
    let first = false;
    function check(b){
        getp(`/preann?kit_id=${kit_id}&check=${b}`).then( (data) => wait(data) );
    }
    check(false);
    function init(){
        audio_context_init({});
        window.ldc.waveforms = [ waveform ];
        loop_init();
    }
    init();
    let auto = false;
    let tdf;
    let sad_with_aws;
    function userf(e){
        let f = e.detail.userf
        if(f == 'delete_all_confirmx'){
            // dispatch('userf', o);
        }
        else{
            if(waveform[f]) waveform[f](e.detail.e);
            else  console.log(`no function ${f}`)
        }
    }
    let settingsc;
    function settingsf() {
        settings.update( (x) => {
            x.open = !x.open;
            return x;
        } );
    }
    let settings_open = false;
    const unsubscribe = settings.subscribe( (x) => {
        settings_open = x.open;
    });
    onDestroy( () => unsubscribe() );
    function one(){
        active_docid.update( () => 's3://coghealth/two/sw02001_m1.wav' )
    }
    function two(){
        // active_docid.update( () => 's3://coghealth/two/sw02001_m1.wav' )
        active_docid.update( () => 's3://coghealth/demo/CarrieFisher10s.wav' )
    }
    const k = Object.keys(window.ldc.resources.urls)[0];
    set_urls(k).then( (x) => {
        if(x.transcript){
            x.transcript.then( (x) => {
                auto = x.found_transcript;
                if(x.use_transcript == 'tdf') tdf = true;
                if(x.use_transcript == 'sad_with_aws') sad_with_aws = true;
                if(document.querySelectorAll('.segment').length > 0) auto = false;
            } );
        }
    } );
</script>

{#if false}
<div class="flex">
<button class="{btn} w-full" on:click={one}>one</button>
<button class="{btn} w-full" on:click={two}>two</button>
</div>
{/if}

{#if settings_open}
    <Modal title="Main Help" open={true}>
        <div slot="body">
            <!-- <HelpScreenMain {close} keyboard={kb} on:show={show} /> -->
            <Settings bind:this={settingsc} />
        </div>
    </Modal>
{/if}


{#if auto}
    <div class="col-6 mx-auto">
        <CreateTranscript {waveform} {data_set_id} bind:auto={auto} {tdf} {sad_with_aws} />
    </div>
{/if}

<Undo bind:this={u} />
<WaveformC   bind:this={w} {waveform} {data_set_id} on:settings={settingsf} />
<Transcript bind:this={t} {waveform}               on:userf={userf} />
