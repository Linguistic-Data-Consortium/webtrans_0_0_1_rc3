<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { tick } from 'svelte'
    import Entry from '../work/input_text_ann_segment.svelte';
    import HelpScreen from '../work/help_screen.svelte'
    import MiniScreenInput from '../work/mini_screen_input.svelte'
    import { set_speaker, open_section, close_section } from './segments_helper'
    import { getp, postp, deletep, patchp } from "../work/getp";
    import { get_promises } from '../work/services'
    import { create_transcript } from './download_transcript_helper'
    import { x as map } from '../waveform/keys_playback'
    import HelpScreenPlaybackHtml from '../waveform/help_screen_playback_html.svelte'
    import { segments, undefined_segments } from './stores'
    import { settings } from '../class_defs/simple_transcription/stores'
    import { update_segments, delete_segments } from '../waveform/segments_helper'
    import { btn } from '../work/buttons'
    let hidden = true;
    let html = null;
    let details_class = 'border p-3 mt-2';
    let term_class = 'text-blue';
    export let ns;
    let segs = [];
    segments.subscribe( (x) => segs = x );
    let undef = [];
    undefined_segments.subscribe( (x) => undef = x );
    // tick().then( () => segsf() );
    export let waveform;
    let readonly;
    let readonly_segs = {};
    export function set_readonly(x){
        readonly = true;
        for(let y of x)
            readonly_segs[y.id] = y;
    }
    let focus = true;
    let active = null;
    export function get_active(){
        return active;
    }
    export function set_active_transcript_line(id, dont_focus){
        let last = active;
        active = id;
        focus = !dont_focus;
        return last;
    }
    export function refocus(){
        let a = active;
        active = null;
        setTimeout( () => active = a, 100);
        focus = true;
    }
    function find_active_i(){
        let found = null;
        // console.log(segs);
        for(let i = 0; i < segs.length; i++){
            if(segs[i].id === active){
                found = i;
                break;
            }
        }
        return found;
    }
    export function find_active_id(){
        let found = find_active_i();
        let h = { id: segs[found].id }
        h.prev = found && found > 0 ? segs[found - 1].id : null;
        h.next = (found || found == 0) && found < segs.length - 1 ? segs[found + 1].id : null;
        return h;
    }
    export function set_active_transcript_line_to_next(){
        if(segs.length == 0){
            return;
        }
        let found = find_active_i();
        let set = null;
        if(found || found == 0){
            if(found < segs.length - 1){
                set = found + 1;
            }
        }
        else{
            set = 0;
        }
        return set_active_transcript_line_wrapper(set, found);
    }
    export function set_active_transcript_line_to_prev(){
        if(segs.length == 0){
            return null;
        }
        let found = find_active_i();
        let set = null;
        if(found || found == 0){
            if(found > 0){
                set = found - 1;
            }
        }
        else{
            set = segs.length - 1;
        }
        return set_active_transcript_line_wrapper(set, found);
    }
    function set_active_transcript_line_wrapper(set, found){
        let h = {}
        if(set || set == 0){
            h.id = segs[set].id;
            h.last = set_active_transcript_line(h.id, false);
        }
        else{
            h.id = segs[found].id;
            h.last = h.id;
        }
        return h;
    }
    let rtl = ldc_nodes.get_constraint('rtl');
    function change_handle(){
        update_segments();
        // validate_transcript();
    }
    function click_transcript_line(e){
        console.log('huh');
        const w = waveform;
        console.log(w.selector);
        console.log(e);
        console.log(this.id);
        w.set_mode_to_cursor()
        w.set_active_transcript_line(this.id);
        console.log(this.dataset.iid);
        // # id = $(this).data().node.meta.id
        // # ldc_nodes.current_hide_show ".ListItem", "#node-#{id}"
        // # console.log $(this).find('input, select')[0].focus()
    }
    function pad(x){
        let s = String(x);
        let dec = s.split('.')[1];
        if(!dec){
            s += '.000';
        }
        else{
            if(dec.length == 2) s += '0';
            if(dec.length == 1) s += '00';
        }
        return s;
    }

    function userf(e, iid){
        const o = { userf: e.detail.userf, e: e.detail.e };
        const h = { iid: iid, help_screen: help_screen, input_screen: input_screen };
        if(e.detail.userf == 'set_speaker')        set_speaker(h);
        else if(e.detail.userf == 'show_sections')  show_sections(h);
        else if(e.detail.userf == 'open_section')  open_section(h);
        else if(e.detail.userf == 'close_section') close_section(h);
        else if(e.detail.userf == 'validate_transcript') validate_transcript();
        else if(e.detail.userf == 'play_head_menu')      play_head_menu(h);
        else                                       dispatch('userf', o);
    }
    function show_sections(){
        settings.update( (x) => {
            x.sections_open = !x.sections_open;
            return x;
        } );
    }
    let help_screen;
    let input_screen;

    let service_promise;
    let output_promise;
    function get1(text){
        const o = { type: 'validate_transcript', data: { text: text } };
        const set_sp = (x) => service_promise = x;
        const set_op = (x) => output_promise = x;
        output_promise = Promise.resolve({ errors: ['validating...'] });
        get_promises(set_sp, set_op, o);
    }
    let transcript;
    $: if(transcript) get1(transcript);
    let include_headers = false;
    let include_speaker = true;
    let include_section = true;
    let kit = window.gdata('.Root').obj._id;
    function validate_transcript(){
        if(output_promise){
            output_promise = null;
        }
        else{
            transcript = create_transcript(kit, include_speaker, include_section, include_headers, segs);
            transcript = transcript.replace(/\t\n/g, "\tx\n");
        }
    }
    function play_head_menu(h){
        // kb = this.keyboards.playback;
        // if (w.special) {
        //   kb.map.p = 'close';
        //   return kb.show_mini_screen(w, false);
        // } else {
          // delete kb.map.p;
          const hh = {
            // html: help_screen.playback,
            html: 'help_screen_playback_html',
            remove: true,
            reset: true,
            mini: true,
            map: map,
            delegate: waveform
          };
          h.help_screen.open(hh);
        // }
    }
</script>

<style>

    .rtl {
        direction: rtl;
    }
    
    .ch1 {
        background-color: Azure;
    }
    
    .ch2 {
        background-color: Lavender;
    }

    .playing-transcript-line {
        background-color: LightGreen;
    }

</style>

<HelpScreen bind:this={help_screen} on:close={ () => refocus() } />
<MiniScreenInput bind:this={input_screen} />

{#if output_promise}
    {#await output_promise}
        <div class="text-center text-red-500">working...</div>
    {:then v}
        {#if v.result != "ok"}
            <!-- <div>{JSON.stringify(v)}</div> -->
            {#each v.errors as x}
                <div class="text-center text-red-500">{x}</div>
            {/each}
        {/if}
    {/await}
{/if}

{#if undef.length}
    <div class="w-96 mx-auto">
        {undef.length} undefined segments found
        <button class="{btn}" on:click={ () => delete_segments(undef) }>Delete?</button>
    </div>
{/if}

<div class="h-48 mt-6 pt-1 overflow-auto {rtl ? 'rtl' : ''} font-mono v-align-middle text-gray-700" >
    {#each segs as x, i}
        <div
            id={x.id}
            class="
                grid grid-cols-12 gap-2
                segment
                segment-{x.iid}
                flex justify-around
                mx-auto
                text-sm
                {x.id === active ? 'text-red-500' : '' }
                {x.docid && x.docid.match(/_A.wav|.wav:A/) ? 'ch1' : ''}
                {x.docid && x.docid.match(/_B.wav|.wav:B/) ? 'ch2' : ''}
            "
            data-iid={x.iid}
            on:click={click_transcript_line}
        >
            <div class="col-span-2 grid grid-cols-3 justify-items-end">
                <div class="colx-span-1">
                    <!-- <div>{x.docid}</div> -->
                    {#if x.docid && x.docid.match(/_A.wav|.wav:A/) ? 'ch1' : ''}
                        <div>A</div>
                    {/if}
                    {#if x.docid && x.docid.match(/_B.wav|.wav:B/) ? 'ch2' : ''}
                        <div>B</div>
                    {/if}
                </div>
                <div class="btime">
                    <div>{pad(x.beg)}</div>
                </div>
                <div class="etime">
                    <div>{pad(x.end)}</div>
                </div>
            </div>
            <div class="col-span-6 text-sm">
                {#if x.id === active}
                    <!-- <input
                        class="transcript-input form-control width-full"
                        type=text
                        value={x.text}
                        use:init
                        {readonly}
                    > -->
                    <Entry
                        node_id={x.iid}
                        name=Transcription
                        on:change={     (e) => change_handle(e, 'change') }
                        on:changelite={ (e) => change_handle(e, 'changelite') }
                        on:userf={ (e) => userf(e, x.iid) }
                        readonly={x.readonly}
                        readonly_text={x.text}
                        {focus}
                        {waveform}
                    />
                {:else}
                    <div class="pl-1 transcript">{x.text}</div>
                {/if}
            </div>
            <div class="col-span-3">
                <div class="flex justify-around">
                    <div class="speaker float-left col-6">
                        <span class=Label>{x.speaker}</span>
                    </div>
                    {#if x.section}
                        <div class="section Label
                            {x.section.end ? "" : ""}
                            height-fit
                        ">
                            {x.section.name}
                        </div>
                    {:else}
                        <div class="Label"></div>
                    {/if}
                </div>
            </div>
        </div>
        {#if x.error}
            <div class="text-center bg-red-100"> {x.error} </div>
        {/if}
    {/each}
</div>
