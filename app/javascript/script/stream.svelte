<!--
This component streams and optionally records audio from the microphone,
the distinction between "stream" and "record" being whether the audio is saved or not.
This parallels the MediaStream and MediaRecorder js objects in terms of terminology.  The MediaStream instance
is passed into the component, but the MediaRecorder instance is created by the
component if recording takes place.
The component is a simple wrapper for functions in audio/record.js,
using the mount/destroy lifecycle to trigger actions.
In other words, the component automatically starts the process when it's created,
and when it's destroyed sends out the result.
-->
<script>
    import { onMount, onDestroy } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    // this function does most of the work
    import { create_analyzer } from '../audio/record.js';
    // timer, just for user feedback
    import Timer from './stop_watch.svelte'
    // rms meter
    import Meter from './meter_wrap.svelte'
    import { rms as rmsf } from '../audio/analysis.js';

    // there's no boolean for streaming because streaming always happens
    export let stream; // MediaStream instance
    // there's a boolean for recording because it's optional
    export let record; // boolean

    // if recording, called by MediaRecorder instance when it stops
    export let onstopf;

    // # opts =
    // #     mimeType: 'audio/webm;codecs=pcm'
    console.log(stream);
    // that.stream_helper1 stream, record

    let rms;
    let timer;
    let o;
    onMount( () => {
        timer.start();
        // the data processing function sets an RMS value in a meter
        const analyzef = (time_domain, freq_domain) => rms.set(rmsf(time_domain));
        o = create_analyzer(stream, record, onstopf, analyzef);
        // the following assignment is what sets the callback to be called
        window.ldc.vars.loop.set('stream_callback', o.analyze);
    } );
    // let time_domain_chunks = [];
    // let hist = ( 0 for i in [0..99])
    // that.hist_total = 0

    // let recorded_chunks = [];
    // let recorded_chunks_rms = [];
    // that.stop_watch_reset()
    // that.stop_watch_start()
    onDestroy( () => {
        timer.stop();
        o.destroy(); // cleanup
        window.ldc.vars.loop.delete('stream_callback'); // stop callback
        dispatch('done', o.chunks); // send recording
    } );
     // this was happening as well with the chunks never being used
    //  if(record){
    //  //     //to save data in recordedChunks array
    //      mediaRecorder.ondataavailable = (e) => chunks2.push(e.data);
    //      mediaRecorder.onstop = onstop_callback;
    //  // 
    //  // that.onstop_callback = -> null
    // }
    // const recording_stats = {
    //     maxw: {
    //         1: 0,
    //         2: 0
    //     },
    //     maxrms: 0,
    //     maxrms12: 0,
    //     maxrmsq: 0,
    //     maxv: 0,
    //     maxmean: 0,
    //     n: 0,
    //     clipped: false
    // }
    // let n = 0;
</script>

<!-- remind the user whether recording is taking place -->
{#if record}
    <div>recording</div>
{:else}
    not recording
{/if}

<!-- timer -->
<div>
    <Timer bind:this={timer} />
</div>

<!-- RMS meter -->
<Meter bind:this={rms} clipped={.99} />
