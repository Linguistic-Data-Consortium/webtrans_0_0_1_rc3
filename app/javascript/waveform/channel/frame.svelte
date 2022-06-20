<script>
    import { active_channel } from '../stores'
    import { times, selection } from '../times'
    export let waveform;
    export let i;
    export let active;
    let width;
    export let time_height_cursor;
    export let wave_canvas_height;
    let height = wave_canvas_height;
    let wave_display_offset;
    times.subscribe( (x) => {
        wave_display_offset = x.wave_display_offset;
        width = x.wave_canvas_width;
        height = wave_canvas_height;
    } );
    selection.subscribe( (x) => {
      draw_cursor();
      draw_selection();
    } );
    function draw_cursor(){
        const w = waveform;
        // console.log 'drawing cursor' if w.debug
        const draw_time = true; // i == 0;
        const cursor_x = w.cursor_x();
        if(cursor_x){
            draw_waveform_line(cursor_x, 'red', draw_time);
        }
    }
    // draws a vertical line on the waveform, optionally with a timestamp
    function draw_waveform_line(x, color, time){
        const w = waveform;
        // if debug is true
        //     console.log "LINE"
        //     console.log w
        //     console.log x
        //     console.log color
        //     console.log time
        //     console.log @time_height_cursor
        // $(ctx).removeLayerGroup(layer).drawLayers()
        // canvas = $(ctx)[0]
        // ctx = canvas.getContext "2d"
        draw_waveform_line_helper(x, color, time, '', height, 0);
    }
    let cursorx;
    let text = '';
    function draw_waveform_line_helper(x, color, time, suffix, y_end, y_start){
        const w = waveform;
        if(x < 0 || x > width){
            return;
        }
        // $("#{selector} .play-head").attr('x1', x)
        cursorx = x;
        if(time){
            text = w.round_to_3_places(w.convert_pixels_to_seconds(x)+wave_display_offset).toString();
        }
    }
    let selection_handle_beg;
    let selection_handle_end;
    function draw_selection(){
        const w = waveform;
        const draw_time = i == 0;
        // const draw_time = true;
        let bpix;
        let epix;
        w.s2p = w.convert_seconds_to_pixels;
        if(w.mousedown_x && ! w.mouseup_x){ // and not w.wave_adjust_scrollbar
            if(w.mousemove_x && ( w.mousedown_x != w.mousemove_x )){
                if(w.mousedown_x < w.mousemove_x){
                    bpix = w.mousedown_x;
                    epix = w.mousemove_x;
                }
                else{
                    bpix = w.mousemove_x;
                    epix = w.mousedown_x;
                }
                if(w.wave_adjust_time){
                    if(w.wave_adjust_btime){
                        bpix = w.mousemove_x;
                        epix = w.s2p(w.wave_selection_end-wave_display_offset);
                    }
                    else{
                        bpix = w.s2p(w.wave_selection_offset-wave_display_offset);
                        epix = w.mousemove_x;
                    }
                }
                draw_waveform_rect(epix, 'red', draw_time, bpix, epix - bpix);
                selection_handle_beg = bpix - 10;
                selection_handle_end = epix - 10;
            }
        }
        else{ // neither w.mouseup_x nor w.mousedown_x
            if(w.wave_selection_offset != null){
                // if w.wave_selection_length is 0
                //     @draw_waveform_line ctx, w.s2p(w.wave_selection_offset-wave_display_offset), 'red', draw_time, @time_height_cursor
                // else
                epix = w.s2p(w.wave_selection_end-wave_display_offset);
                bpix = w.s2p(w.wave_selection_offset-wave_display_offset);
                let ww = w.s2p(w.wave_selection_length);
                draw_waveform_rect(epix, 'red', draw_time, bpix, ww);
                selection_handle_beg = bpix - 10;
                selection_handle_end = epix - 10;
            }
        }
    }

    let selection_x;
    let selection_width;
    let selection_beg_x;
    let selection_end_x;
    let selection_beg_text = '';
    let selection_end_text = '';
    // draws a selection rectangle on a waveform, optionally with timestamps
    function draw_waveform_rect(x2, color, time, start_x, w){
        const ww = waveform;
        // ctx.fillStyle = color
        // ctx.globalAlpha = 0.5
        // ctx.fillRect start_x, 0, w, ww.wave_canvas_height

        // console.log start_x
        selection_x = start_x;
        selection_width = w;
        // console.log('drawing')
        // console.log(selection_width)
        if(time){
            if(color == 'white'){
                color = 'black';
            }
            else{
                color = 'white';
            }
            color = 'black';
            selection_beg_text = ww.round_to_3_places(ww.convert_pixels_to_seconds(x2)+wave_display_offset).toString();
            // ctx.strokeText text, x2, 0
            // x: x2 //- 50
            selection_beg_x = x2;
            selection_end_text = ww.round_to_3_places(ww.convert_pixels_to_seconds(start_x)+wave_display_offset).toString();
            selection_end_x = start_x;
            // ctx.strokeText text, (start_x - 40), 0
        }
    }
    function mousemove(e){
        const w = waveform;
        w.set_mode_to_cursor();
        w.mousemove_x = e.clientX - this.getBoundingClientRect().left;
        w.set_move_params();
        if(active){
          draw_cursor();
          draw_selection();
        }
    }
    function mousedown(e){
        const w = waveform;
        w.set_mode_to_cursor();
        w.mousedown_x = e.clientX - this.getBoundingClientRect().left;
        w.set_mousedown_true();
        active = true;
        active_channel.update( () => i );
    }
    function mouseup(e){
        const w = waveform;
        w.set_mode_to_cursor();
        w.mouseup_x = e.clientX - this.getBoundingClientRect().left;
        w.set_mousedown_false();
    }

</script>

<style>

text {
    font: 8px sans-serif;
    text-anchor: left;
    user-select: none;
}

svgx {
  position: absolute;
  top: 0;
  left: 0;
  background-color: transparent;
  z-index: 2;
  cursor: crosshair;
}

svg text {
    -webkit-user-select: none;
       -moz-user-select: none;
        -ms-user-select: none;
            user-select: none;
}
svg text::selection {
    background: none;
}
.selection-handle {
    cursor: col-resize;
}
</style>
<!-- width {width} {cursorx} {height} -->
<!-- because we're capturing mouse events, we use "relative z-10" on the svg -->
<svg
    {width}
    {height}
    class="waveform-svg relative z-10"
    on:mousemove={mousemove}
    on:mousedown={mousedown}
    on:mouseup={mouseup}
    on:mouseleave={mouseup}
>
    {#if active}
        <line class="cursor" x1={cursorx} x2={cursorx} y1={0} y2={height} stroke="red" />
        <text class="cursor-time" x={cursorx} y={time_height_cursor+10}>{text}</text>
        <rect class="selection" x={selection_x} width={selection_width} {height} fill="red" opacity="0.5" />
        <text class="selection-time-beg" x={selection_beg_x} y="10">{selection_beg_text}</text>
        <text class="selection-time-end" x={selection_end_x} y="10">{selection_end_text}</text>
        <rect class="selection-handle selection-handle-beg" x={selection_handle_beg} width="20" {height} opacity="0" />
        <rect class="selection-handle selection-handle-end" x={selection_handle_end} width="20" {height} opacity="0" />
    {/if}
</svg>
