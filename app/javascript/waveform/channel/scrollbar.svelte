<script>
    import { onDestroy } from 'svelte';
    import { times } from '../times'
    export let waveform;
    let width;
    export let height;
    let start_x;
    let ww;
    function draw_scrollbar(){
        // adds 20 ms or more to draw scrollbar
        const w = waveform;
        // console.log w.wave_audio
        start_x = wave_display_offset / w.wave_audio.etime * width;
        ww      = wave_display_length / w.wave_audio.etime * width;
        // color = 'red'
        // rect = $(".waveform-scrollbar rect")
        // rect.attr 'x', start_x
        // rect.attr 'width', ww
    }
    let wave_display_offset;
    let wave_display_length;
    const unsubscribe = times.subscribe( (x) => {
        width = x.wave_canvas_width;
        wave_display_offset = x.wave_display_offset;
        wave_display_length = x.wave_display_length;
        draw_scrollbar();
    } );
    onDestroy( () => unsubscribe() );
</script>

<style>
    svgx {
         position: absolute;
         top: 145px;
         cursor: move;
         z-index: 9;
    }
</style>

{#if start_x || start_x == 0}
    <svg {width} {height} class="waveform-scrollbar">
        <rect x={start_x} width={ww} height="100%" fill="red" opacity="0.5" />
    </svg>
{/if}
