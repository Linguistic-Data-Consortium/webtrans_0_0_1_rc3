<script>
    import { onMount } from 'svelte';
    export let url;
    let audio;
    let src;
    onMount(() => {
        audio.controls = true;
        src = url;
    });

    let duration;
	let buffered;
	let played;
	let seekable;
	let seeking;
	let ended;
	let currentTime;
	let playbackRate;
	let paused;
	let volume;
	let muted;

</script>

<audio
    bind:this={audio}
    {src}
    bind:duration
	bind:buffered
	bind:played
	bind:seekable
	bind:seeking
	bind:ended
	bind:currentTime
	bind:playbackRate
	bind:paused
	bind:volume
	bind:muted
></audio>
<div>{duration} seconds</div>
<div><a href={url} download>download</a></div>
