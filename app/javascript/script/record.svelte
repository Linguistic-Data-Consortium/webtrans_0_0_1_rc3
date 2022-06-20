<script>
    import { btn, cbtn, dbtn } from "../work/buttons"
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { audio_context_init } from '../audio/audio_context';
    import { loop_init } from '../audio/loop';
    import { getUserMedia, create_blob, filename_from_date } from '../audio/record';
    import { play_callback, waveform_callback } from '../audio/play';
    import Stream from './stream.svelte'
    import AudioPlayer from './audio_player.svelte';
    // import Upload from './input_upload_auto'
    let stream = false;
    let record = false;
    let media;
    function init(){
        audio_context_init({});
        loop_init();
        // window.ldc.vars.loop.set('play_callback', play_callback);
        // window.ldc.vars.loop.set('waveform_callback', waveform_callback);
    }
    function streamf(){
        init();
        stream = true;
        media = getUserMedia();
    }
    function start(){
        init();
        stream = true;
        record = true;
        media = getUserMedia();
    }
    function stop(){
        stream = false;
        record = false;
        media = null;
    }
    function onstopf(){
        console.log('done');
    }
    let chunks = [];
    let blob;
    let url;
    function done(e){
        chunks = e.detail;
        blob = create_blob(chunks);
        url = URL.createObjectURL(blob);
        dispatch('return', blob);
    }
    let filename = filename_from_date();

    let ch1;
    let waveform;
    let two;
    let active_channel;
    let activate2;
    // let btn = "group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md bg-gray-50 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500";
</script>

{filename}

<div class=clearfi>
    <div class="mx-auto px-5">
        <!-- <div>
            <div class="form-group">
                <div class="form-group-header">
                    <label for="input-scale">
                        <input
                            id="input-scale"
                            type=checkbox
                            bind:checked={scale}
                        />
                        Scale samples to max
                    </label>
                </div>
            </div>
        </div> -->
        <div class="flex justify-center space-x-4 ">
            {#if stream}
                <div>
                    <button class={btn} style="width: 150px; height: 50px" on:click={stop}><i class="fa fa-stop"></i></button>
                </div>
            {:else}
                <div>
                    <div>stream only</div>
                    <div><button class={btn} on:click={streamf}><i class="fa fa-microphone"></i></button></div>
                </div>
                <div>
                    <div>record audio</div>
                    <div><button class={btn} on:click={start}><i class="fa fa-circle"></i></button></div>
                </div>
            {/if}
        </div>
        {#if stream}
            <div>stream/record</div>
            {#if media}
                {#await media}
                    waiting
                {:then stream}
                    <Stream
                        {stream}
                        {record}
                        {onstopf}
                        on:done={done}
                    />
                {/await}
            {/if}
        {:else if chunks.length > 0}
            {chunks.length} chunks
            <AudioPlayer {url} />
            <!-- <SimpleInput label="Filename" bind:value={filename} /> -->
            <!-- <Upload {blob} /> -->
            <!-- <Channel bind:this={ch1} {waveform} i={0} {two} active={active_channel == 0} on:active={activate2} /> -->
        {/if}
    </div>
</div>
