<script>
    import { onDestroy } from 'svelte'
    import { srcs } from '../../work/sources_stores'
    import { times } from '../times'
    export let waveform;
    export let i;
    let width;
    export let height;
    let draw_underlines_flag = true;
    let srcso;
    function update(o){
        srcso = o;
        const w = waveform;
        // let p = window.sources_object.draw_underlines_audio(w, '.waveform-underlines');
        // let o = window.sources_object.get_sources();
        let p = draw_underlines(w.wave_docid, o);
        if(w.wave_docid.match(/:A$/) && i == 1) p = draw_underlines(w.wave_docid.replace(/:A$/,':B'), o);
        // p.then( () => {
            console.log('done with update')
            console.log(o);
            // $('.SegmentList').css 'margin-top', parseInt($(that.selector_underlines).attr('height'))
        // } );
    }
    let underline_height = 5;
    let underlines = [];
    let wave_display_offset;
    let wave_display_length;
    const unsubscribe = srcs.subscribe( (x) => update(x) );
    const unsub2 = times.subscribe( (x) => {
        wave_display_offset = x.wave_display_offset;
        wave_display_length = x.wave_display_length;
        width = x.wave_canvas_width;
        update(srcso);
    } );
    onDestroy( () => { unsubscribe(); unsub2(); } );
    //this function draws the underlines for a given line
    function draw_underlines(docid, srcs){
        if(!draw_underlines_flag){
            return;
        }
        const w = waveform;
        // const docid = w.wave_docid;
        // return sources[docid].then( (data) => { // sorc
            // if true //debug is true
            //     console.log 'underlines'
            //     console.log docid
            //     console.log w
            // console.log(data);
            let max_level = 0;
            if(srcs[docid] == undefined){
                return;
            }
            if(docid.match(/:B$/) && i == 0) return;
            if(docid.match(/:A$/) && i == 1) return;
            //cycle through the sources and find the maximum level
            // $.each srcs[docid], (k, src) ->
            for(const k in srcs[docid]){
                let src = srcs[docid][k];
                if(src.level > max_level){
                    max_level = src.level;
                }
            }
            // console.log max_level
            const line_obj = {}
            // data.line_obj = line_obj;
            //calculate the height based on the maximum level, width based on the line width
            line_obj.underlines_height = (max_level + 1) * (underline_height * 2 + 1);
            line_obj.underlines_width = width;
            line_obj.underlines_selector = '.waveform-underlines';
            //cycle through the sources for this line, compute the width and offset, and draw the underline
            // console.log('U1');
            // console.log(srcs);
            const a = [];
            // $.each srcs[docid], (i, src) ->
            for(const k in srcs[docid]){
                // console.log('U2');
                let src = srcs[docid][k];
                // console.log(src)
                if(src.end >= wave_display_offset && src.beg <= (wave_display_length + wave_display_offset)){
                    // console.log 'U3'
                    // scale_factor = wave_canvas_width / wave_display_length
                    // leftn = char_index[src.beg][1];
                    // linen = char_index[src.beg][0];
                    //stringWidth = that.get_width(orig.substring(src.beg, src.end+1));
                    let offset = ( src.beg - wave_display_offset ) / w.wave_scale;
                    let width = ( src.end - src.beg ) / w.wave_scale;
                    let debug = false;
                    if(debug){
                        console.log("DEBUG");
                        console.log(src);
                        console.log(offset);
                        console.log(width);
                    }
                    let aa = draw_underline(offset, width, src.level, src.node);
                    if(aa){
                        a.push(aa);
                    }
                }
            }
            underlines = a;
            // a = '' if a[0] is undefined
            // $('selector').replaceWith ldc_nodes.array2html [ 'svg', 'xmlns', "http://www.w3.org/2000/svg", 'class', 'waveform-underlines', a ]
            // console.log ldc_nodes.array2html [ 'svg', 'xmlns', "http://www.w3.org/2000/svg", 'class', 'waveform-underlines', a ]
            width = line_obj.underlines_width;
            height = line_obj.underlines_height;
        // } );
    }
    function draw_underline(offset, width, depth, node_id){
        // console.log "U4 #{offset} #{width} #{node_id}" if @debug
        // const node = window.gdata(`#node-`node_id);
        // if(node == false){
        //     return;
        // }
        // let underline_info = window.sources_object.draw_underline_helper2(node);
        // if(underline_info.bool == false){
        //     return;
        // }
        // let underline_color = underline_info.color;
        let underline_color = 'blue';
        // depth = depth * ( underline_height * 2 + 1 )
        depth = depth * ( underline_height + 5 + 1 ); // instead of doubling, just add 5
        let o = {
            node_id: node_id,
            class: `underline-rect-${node_id}`,
            width: width,
            // height: @underline_height
            x: offset,
            y: depth,
            fill: underline_color
        }
        // a = [ 'rect' ]
        // for k, v of o
        //     a.push k
        //     a.push v
        // a.push ''
        return o;
    }
    function underline(x){
        const w = waveform;
        const id = w.rmap.get(window.$(`#node-${x.node_id}`).closest('.ListItem').attr('id'));
        w.set_active_transcript_line(id);
        return w.play_current_span();
    }
</script>

<style>
svgx {
    position: absolute;
    top: 165px;
}
</style>

<svg {width} {height} class="waveform-underlines">
    {#each underlines as x}
        <rect
            class={x.class}
            width={x.width}
            height={underline_height}
            x={x.x}
            y={x.y}
            fill={x.fill}
            on:click={ () => underline(x) }
        />
    {/each}
</svg>
