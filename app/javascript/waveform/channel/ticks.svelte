<script>
    import { onDestroy } from 'svelte';
    import { times } from '../times'
    export let waveform;
    let width;
    let wave_display_offset;
    let wave_display_length;
    export let height;
    let a = [];
    const unsubscribe = times.subscribe( (x) => {
        wave_display_offset = x.wave_display_offset;
        wave_display_length = x.wave_display_length;
        if(width != x.wave_canvas_width && wave_display_length){
            width = x.wave_canvas_width;
            draw_ticks();
        }
        if(a.length) draw_tick_times();
    } );
    onDestroy( () => unsubscribe() );
    function draw_ticks(){
        const w = waveform;
        // console.log selector

        // even when false, this adds time, maybe 10 ms.  must be the extra layers
        //if true// w.stereo is false or first is false
        // adds about 50ms to draw time
        // for i in [1..9]
        //     step = wave_canvas_width / 10
        //     this.draw_waveform_line_helper waveform, i*step, layer, 'black', true, "-#{i}", waveform_display.time_height_ticks+30, waveform_display.time_height_ticks, waveform_display.time_height_ticks
        let step = Math.floor(w.wave_scale*8000) / 200; // part of this operation is scaling, and part is arbitrary step frequency
        step = wave_display_length / 40;
        w.step1 = w.wave_scale;
        w.step2 = step;
        w.step3 = w.step2 * 2;
        w.step4 = w.step3 * 3;
        w.step2 = step * 2 / 5;
        // display.step = step
        // tick_offset = Math.floor(wave_display_offset / step) * step
        // const tick_offset = wave_display_offset;
        // if(true) //@debug is true
        //     console.log( "tick offset: #{tick_offset}")
        //     console.log( w.convert_pixels_to_seconds tick_offset)
        //     console.log( "length: #{wave_display_length}")
        //     console.log( "step: #{step}")
        //     console.log( w.wave_scale)
        a = [];
        for(let i = 1; i < 40; i++){
            let ii = w.round_to_6_places(i*step);
            if(i % 2 == 0){
                // this.draw_tick waveform, ii, layer, 'black', true, "-#{i}", waveform_display.time_height_ticks+30, waveform_display.time_height_ticks, waveform_display.time_height_ticks
                draw_tick(ii, true, i);
            }
            else{
                draw_tick(ii, false, i);
            }
        }
    }

    let time_height = 0;
    function draw_tick(time_point, time, i){
        const w = waveform;
        let y_start = 0;
        let y_end = 10;
        const x = time_point / (wave_display_length / width);
        // const x = w.convert_seconds_to_pixels(time_point - wave_display_offset);
        if(x < 0 || x > width){
            return;
        }
        if(!time){
            y_start += 5;
        }
        // ctx.moveTo x, y_start
        // ctx.lineTo x, y_end
        const o = { x: x, y_start: y_start, y_end: y_end };
        if(time){
            const text = time_point.toString()
            // ctx.font = '8pt sans-serif'
            // ctx.strokeText text, x - 7, time_height + 18
            o.time_x = x;
            o.text = '123.4';
        }
        a.push(o);
    }

    function draw_tick_times(){
        // console.log 'TICK TIMES'
        const w = waveform;
        let step = Math.floor(w.wave_scale*8000) / 200;
        step = wave_display_length / 40;
        for(let i = 1; i < 40; i++){
            let ii = w.round_to_3_places(i*step+wave_display_offset);
            if(i % 2 == 0){
                a[i-1].text = ii.toString();
            }
        }
    }
</script>

<style>
    svgx {
        position: absolute;
        top: 125px;
    }
    text {
        font: 8px sans-serif;
        text-anchor: left;
        user-select: none;
    }
</style>

<svg {width} {height} class="waveform-ticks">
    {#each a as x}
        <line x1={x.x} y1={x.y_start} x2={x.x} y2={x.y_end} stroke=black />
        {#if x.time_x}
            <text x={x.time_x} y={time_height+18}>{x.text}</text>
        {/if}
    {/each}
</svg>
