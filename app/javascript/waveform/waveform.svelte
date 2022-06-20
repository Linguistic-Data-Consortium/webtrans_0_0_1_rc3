<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { onMount, onDestroy } from 'svelte';
    // import { watchResize } from "svelte-watch-resize";
    // import JSONTree from 'svelte-json-tree';
    import { getp, postp, deletep, patchp } from "../work/getp";
    import { getSignedUrlPromise } from '../work/aws_helper'
    import Channel from '../waveform/channel/channel.svelte';
    import HelpScreenMain from '../waveform/help_screen_main.svelte';
    import HelpScreenWaveform from '../waveform/help_screen_waveform.svelte';
    import HelpScreenInput from '../waveform/help_screen_input.svelte';
    import HelpScreenPlayback from '../waveform/help_screen_playback.svelte';
    import HelpScreenServices from '../waveform/help_screen_services.svelte';
    import AddSad from '../waveform/add_sad.svelte'
    import UploadTranscript from '../waveform/upload_transcript.svelte';
    import DownloadTranscript from '../waveform/download_transcript.svelte';
    import CloseKit from '../waveform/close_kit.svelte';
    import KeyboardIcon from './keyboard_icon.svelte'
    import { play_src_with_audio, is_playing, stop_playing } from '../audio/play';
    import { play_callback, waveform_callback, create_audio_element_from_url, set_audio_to_channel } from '../audio/play';
    import Modal from '../modal.svelte'
    import DeleteAllConfirmModal from './delete_all_confirm_modal.svelte'
    import { btn, dbtn } from '../work/buttons'
    import { active_docid, active_channel, spectrogram_settings } from './stores'
    import Settings from './settings.svelte'
    import { Keyboard } from '../work/keyboard'
    import { times } from './times'
    import { get_audio_buffer_info_for_waveform } from '../audio/buffer'
    import { set_urls } from '../waveform/aws_helper'
    let ns = window.ldc.ns;
    export let waveform;
    export let data_set_id;
    let i = 0;
    let id = `node-${waveform.node.meta.id}-waveform-${i}`;
    let id2 = `node-${waveform.node.meta.id}-waveform-${i+1}`;
    let div;
    let audios;
    let audio_object;
    let audio_elements = {};

    function get_audio_element_helper(id){
        if(id && !audio_elements[id]){
            audio_elements[id] = create_audio_element(id);
            audios.push({
                docid: id,
                audio: audio_elements[id],
                play_head: 0
            });
        }
    }

    function get_audio_element(){
        audios = [];
        get_audio_element_helper(waveform.docid);
        get_audio_element_helper(waveform.docid2);
        audio_object = audios[0];
    }


    function create_audio_element(id){
        console.log("ELEMENT");
        console.log(id);
        return new Promise( (resolve, reject) => {
            waveform.is_playing = is_playing;
            set_urls(id).then( (x) => resolve(create_audio_element_from_url(x.wav_url, waveform)) );
        } );
    }
    // const interval = setInterval( () => {
    //     if(waveform.docid && waveform.docid.match(/wav$/)){
    //         get_audio_element();
    //         clearInterval(interval);
    //     }
    // }, 500 );
    // let width;
    // let height;
    // function set_width(){
    //     const w = waveform;
    //     w.wave_canvas_width = div.offsetWidth;
    //     // w.wave_scale = w.wave_display_length / w.wave_canvas_width;
    //     helper.sample_calculations();
    //     // width = w.wave_canvas_width;
    //     // height = w.wave_canvas_height;
    //     // $("#{w.selector}-waveform-#{@i} canvas").each (i, x) ->
    //     //     c = $(x)[0]
    //     //     c.width = w.wave_canvas_width
    //     //     c.height = w.wave_canvas_height
    //     // $("#{w.selector}-waveform-#{@i} svg").each (i, x) ->
    //     //     h = if i < 2 then w.wave_canvas_height else 20
    //     //     $(x).attr 'width', w.wave_canvas_width
    //     //     $(x).attr 'height', h
    // 
    // }
    onMount( () => {
        times.update( (x) => {
            return {
                wave_display_offset: x.wave_display_offset,
                wave_display_length: x.wave_display_length,
                wave_canvas_width: div.offsetWidth
            }
        } );
    } );
    let ch1;
    let ch2;
    // export function update(){
    //     set_width();
    //     const w = waveform;
    //     ch1.update();
    //     if(ch2) ch2.update();
    // }
    // function fill_cache(k, buffer, ch, t){
    //     if(ch == 'A') ch1.fill_cache(k, buffer, t);
    //     if(ch == 'B') ch2.fill_cache(k, buffer, t);
    // }
    // function draw_buffer(k, ch, t){
    //     if(ch == 'A') ch1.draw_buffer(k, t);
    //     if(ch == 'B') ch2.draw_buffer(k, t);
    // }
    function resize(node){
        update();
        waveform.cache = {}
        waveform.update_waveform = true;
    }
    let active_channeln = 0;
    function activate(active_channel){
        active_channeln = active_channel;
        if(audios){
            audio_object = audios[active_channel];
            waveform.wave_docid = active_channel == 0 ? waveform.docid : waveform.docid2;
            if(waveform.stereo) set_audio_to_channel(audio_elements[waveform.wave_docid], active_channel);
        }
    }
    export function play_src(src, f){
        console.log('AUDIO')
        console.log(audio_object);
        play_src_with_audio(audio_object, src, f);
    }
    export function play_current_span_or_play_stop(){
        if(waveform.wave_selection_length == 0)
            play_stop();
        else
            play_current_span();
    }
    export function play_current_span(){
        const w = waveform;
        if(w.wave_selection_length == 0){
            alert('select a region first');
        }
        else{
            const src = {
                beg: w.wave_selection_offset,
                end: w.wave_selection_offset + w.wave_selection_length
            };
            play_src(src, () => null);
        }
    }
    
    function play_stop(){
      if(is_playing())
        stop_playing()
      else
        play_from_play_head()
    }
    export function play_from_play_head(){
        const w = waveform;
        const src = {
            beg: w.play_head,
            end: w.wave_audio.etime
        };
        play_src(src, () => null);
    }
    export function stopplaying(){ stop_playing(); }
    export function play_from_cursor(){
        const w = waveform;
        w.play_head = w.convert_pixels_to_seconds(w.cursor_x()) + w.wave_display_offset;
        play_from_play_head();
    }
    export function play_from_selection_beg(){
        const w = waveform;
        if(w.wave_selection_offset){
            w.play_head = w.wave_selection_offset;
            play_from_play_head();
        }
    }
    export function play_from_selection_end(){
        const w = waveform;
        if(w.wave_selection_offset){
            w.play_head = w.wave_selection_offset + w.wave_selection_length;
            play_from_play_head();
        }
    }
    // get_audio_buffer_info_for_waveform(waveform);

    let two = waveform.docid.match(/_A\.wav/) ? true : false;
    if(two){
        window.ldc.vars.loop.set('play_callback', play_callback);
        window.ldc.vars.loop.set('waveform_callback', waveform_callback);
    }
    else{
        // let interval = setInterval( () => {
        // waveform.bufferp.then( () => check_stereo() );
            window.ldc.vars.loop.set('play_callback', play_callback);
            window.ldc.vars.loop.set('waveform_callback', waveform_callback);
    }
    function check_stereo(){
            console.log(waveform.stereo);
            if(waveform.stereo !== null){
                two = waveform.stereo;
                // clearInterval(interval);
                if(two){
                    const w = waveform;
                    const k = w.wave_docid;
                    const new_docid = w.wave_docid + ':A';
                    w.docid = new_docid;
                    // spelling out waveform on the next line gets reactivity below
                    waveform.wave_docid = new_docid;
                    w.wave_audio.id = new_docid;
                    w.docid2 = new_docid.replace(':A', ':B');
                    // for( let k of Object.keys(audio_elements)){
                        let kk = k + ':A';
                        let v = audio_elements[k];
                        audio_elements[kk] = v;
                        audios[0] = {
                            docid: kk,
                            audio: v,
                            play_head: 0
                        };
                        kk = k + ':B';
                        audio_elements[kk] = v;
                        audios[1] = {
                            docid: kk,
                            audio: v,
                            play_head: 0
                        };
                    // }
                    audio_object = audios[0];
                    set_audio_to_channel(v, 0);
                }
            }
    }
    let help_screen;
    let kb;
    export function show_help_screen_main(x){
        help_screen = 'main';
        kb = x;
        kb.root_hide()
    }
    let close = () => {
        help_screen = null;
    }
    let show_upload_transcript = false;
    export function upload_transcript(){
        show_upload_transcript = true;
    }
    function asr(){
        waveform.activate_sr()
    }
    let show_asr = false;
    // setInterval( () => {
    //     let t = window.gdata('.Root').obj.task_id;
    //     if(t == 36) show_asr = true;
    // }, 100 );
    const permission_to_download = window.ldc_nodes.get_constraint('export_transcript') || window.permissions.project_manager ||
        (window.ldc_nodes.get_constraint('export_transcript_to_task_admin') && window.permissions.task_admin);
    function show(e){
        help_screen = e.detail;
        if(help_screen =='open_guidelines'){
            help_screen = null;
            waveform.open_guidelines();
        }
    }
    function service(e){
        help_screen = 'add_sad';
    }
    function userf(e){
        const o = { userf: e.detail.userf, e: e.detail.e };
        // const h = { help_screen: help_screen, input_screen: input_screen };
        let f = o.userf;
        if(f == 'delete_all_confirm'){
            open_deletem = true;
        }
        else if(f == 'settings'){
            dispatch('settings')
        }
        else if(f == 'spectrogram'){
            settingsc.open();
            // ch1.spectrogramf();
            // ch2.spectrogramf();
            // spectrogram_settings.update( (x) => {
            //     x.spectrogram_open = !x.spectrogram_open;
            //     return x;
            // });
        }
        else{
            if(waveform[f]) waveform[f](o.e);
            else  console.log(`no function ${f}`)
        }
    }
    let open_deletem = false;
    let settingsc;
    let wave_docid;
    active_docid.subscribe( (x) => {
        const w = waveform;
        w.docid = x;
        if(x.match(/_A\.wav/)) w.docid2 = x.replace(/_A/g, '_B');
        w.wave_audio.id = x;
        // btime: @node.value.beg
        // etime: @node.value.end
        w.wave_docid = x;
        get_audio_buffer_info_for_waveform(waveform);
        waveform.bufferp.then( () => {
            wave_docid = x;
            get_audio_element();
            check_stereo();
            activate(0);
        } );
    } );
    active_channel.subscribe( (x) => activate(x) );
    let wave_display_offset;
    let wave_display_length;
    times.subscribe( (x) => {
        wave_display_offset = x.wave_display_offset;
        wave_display_length = x.wave_display_length;
    } );
</script>

<style>
.activech {
  box-shadow: inset 0 0 5px green;
}
</style>

<Settings bind:this={settingsc} />

{#if open_deletem}
    <DeleteAllConfirmModal on:close={ () => open_deletem = false } {waveform} />
{/if}

{#if help_screen == 'main'}
    <Modal title="Main Help" open={true}>
        <div slot="body">
            <HelpScreenMain {close} keyboard={kb} on:show={show} />
        </div>
    </Modal>
{:else if help_screen == 'show_help_screen_waveform'}
    <Modal title="Waveform Help" open={true}>
        <div slot="body">
            <HelpScreenWaveform on:show={show} />
        </div>
    </Modal>
{:else if help_screen == 'show_help_screen_input'}
    <Modal title="Transcript Input Help" open={true}>
        <div slot="body">
            <HelpScreenInput on:show={show} />
        </div>
    </Modal>
{:else if help_screen == 'show_help_screen_playback'}
    <Modal title="Playback Help" open={true}>
        <div slot="body">
            <HelpScreenPlayback on:show={show} />
        </div>
    </Modal>
{:else if help_screen == 'show_help_screen_services'}
    <Modal title="Services" open={true}>
        <div slot="body">
            <HelpScreenServices on:show={show} on:service={service} />
        </div>
    </Modal>
{:else if help_screen == 'add_sad'}
    <Modal title="Add SAD" open={true}>
        <div slot="body">
            <AddSad on:show={show} />
        </div>
    </Modal>
{/if}


    <!-- "#{w.selector}").before ldc_nodes.array2html <div', [ -->
<div id="node-00-header" class="grid grid-cols-5">
    <div class="filename col-span-2">{wave_docid}</div>
    <div class="filename col-span-1">{wave_display_offset} {wave_display_offset+wave_display_length}</div>
    <div class="filename col-span-1">{wave_display_length}</div>
    <div class="col-span-1">
        <div class="grid grid-cols-12">
            {#if window.ldc_nodes.get_constraint('import_transcript_auto') || window.permissions.project_manager}
                <div class="col-span-2">
                    <!-- <UploadTranscript {ns} {waveform} {data_set_id} /> -->
                </div>
            {/if}
            {#if permission_to_download}
                <div class="col-span-2">
                    <DownloadTranscript />
                </div>
            {/if}
            <div class="col-span-2 float-left">
                <CloseKit />
            </div>
            {#if show_asr}
                <div class="col-span-1 float-left" on:click={asr}>
                    <i class="fa fa-font"></i>
                </div>
            {/if}
            <div class="mode text-center col-span-3 float-left">{waveform.mode}</div>
            <div class="col-span-2 float-left">
                <KeyboardIcon {waveform} on:userf={userf} />
            </div>
        </div>
    </div>
</div>
<!-- <div bind:this={div} id="node-00" class="ChannelA Waveform active_channel" use:watchResize={resize}> -->
<div bind:this={div} id="node-00" class="ChannelA Waveform active_channel" >
    <div id={id} class="node-waveform {active_channeln == 0 ? 'activech': ''}">
        <Channel bind:this={ch1} {waveform} i={0} {two} />
    </div>
    {#if two}
        <div id={id2} class="node-waveform {active_channeln == 1 ? 'activech': ''}">
            <Channel bind:this={ch2} {waveform} i={1} {two} />
        </div>
    {/if}
</div>
