<script>
    import { onMount, onDestroy, createEventDispatcher } from 'svelte'
    const dispatch = createEventDispatcher();
    import Segments from './segments.svelte'
    import Sections from './sections.svelte'
    import { settings } from '../class_defs/simple_transcription/stores'
    let segments = null;
    let sections = null;
    let show = 'segments';
    let ns = window.ldc.ns;
    export let waveform;
    let readonly = false;
    export function get_active(){
        return segments.get_active();
    }
    export function set_active_transcript_line(id, dont_focus){
        return segments.set_active_transcript_line(id, dont_focus);
    }
    export function refocus(){ segments.refocus(); }
    export function find_active_id(){
        return segments.find_active_id();
    }
    export function set_active_transcript_line_to_next(){
        return segments.set_active_transcript_line_to_next();
    }
    export function set_active_transcript_line_to_prev(){
        return segments.set_active_transcript_line_to_prev();
    }
    let sections_open;
    const unsubscribe = settings.subscribe( (x) => sections_open = x.sections_open );
    onDestroy( () => unsubscribe() );
</script>

<style>
</style>

{#if sections_open}
    <Sections bind:this={sections} {ns} />
{/if}

<Segments bind:this={segments} {ns} {waveform} on:userf />
