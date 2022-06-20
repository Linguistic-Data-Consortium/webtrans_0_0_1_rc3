<script>
    export let waveform;
    export let i;
    export let active;
    let width;
    let height;
    export let time_height_cursor;
    export let wave_canvas_height;
    let x;
    let text = '123.456';
    function draw_play_head(){
        if(!active) return;
        const w = waveform;
        width = w.wave_canvas_width;
        height = wave_canvas_height;
        const draw_time = true; // i == 0;
        // adds 50 ms or more to draw play head
        x = w.convert_seconds_to_pixels(w.play_head - w.wave_display_offset);
        // canvas = $(selector)[0]
        // ctx = canvas.getContext "2d"
        // ctx.clearRect 0, 0, canvas.width, canvas.height
        // ctx.beginPath()
        // @draw_waveform_line @selector_play_head, x, 'green', draw_time


        if(x < 0 || x > width){
            return;
        }
        if(draw_time){
            text = w.round_to_3_places(w.convert_pixels_to_seconds(x)+w.wave_display_offset).toString();
        }
    }
    waveform.playheads.set(i, draw_play_head);
</script>

<style>
</style>

<svg {width} {height} class="waveform-play-head">
    <line class="play-head" x1={x} x2={x} y1={0} y2={height} stroke="green" />
    <text class="play-head-time" {x} y={time_height_cursor+10}>{text}</text>
</svg>
