<script>
    import { onMount } from 'svelte';
    import SimpleInput from './simple_input';
    import AudioPlayer from 'script/audio_player';
    import InputUpload from './input_upload.svelte'
    import { ParseB } from '../waveform/parse_b'
    export let chunks;
    export let scale;
    
    let filename;
    
    let audio;
    let url;
    
    onMount(() => {
        // # audio = $('<audio></audio>')[0]
        // # $('.Root').append audio
        url = URL.createObjectURL(blob);
    });

</script>

{chunks.length} chunks

{#if url}
    <AudioPlayer {url} />
{/if}
