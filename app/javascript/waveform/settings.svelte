<script>
    import { spectrogram_settings } from './stores'
    import HelpScreen from '../work/help_screen.svelte';
    import MiniScreenInput from '../work/mini_screen_input.svelte';
    export let settings = false;
    // export let help_screen;
    export function b(){console.log('xfx')} 
    export function close(){ return 'close' }
    export function get_map(){ return map }
    let h = {};
    h.height = 125; 
    h.fft_size = 128;
    h.frame_time = .1;
    h.time_step = .1;
    const all = [
        'height',
        'fft_size',
        'frame_time',
        'time_step',
    ];
    spectrogram_settings.subscribe( (x) => {
        console.log(x)
        if(x.height) h.height = x.height;
        if(x.fft_size) h.fft_size = x.fft_size;
        if(x.frame_time) h.frame_time = x.frame_time;
        if(x.time_step) h.time_step = x.time_step;
        console.log('now')
        console.log(x.fft_size);
    });
    function ch(x){
        if(focus){
            h[focus] += x;
            spectrogram_settings.update( (x) => {
                x.height = h.height;
                x.wave_canvas_height = h.wave_canvas_height;
                return x;
            });
        }
    }
    function ch2(xx){
        spectrogram_settings.update( (x) => {
            console.log(focus)
            if(focus == 'height') x.height = h.height;
            x[focus] = xx;
            return x;
        });
    }

    let focus;
    let cfq;
    let const1 = [ -10, -25, -50, -100, 10, 25, 50, 100 ];
    function cf(e){
        if(e.key == 'q'){
            focus = 'wave_canvas_height';
            cfq = make_cfq([ -10, -25, -50, -100, 10, 25, 50, 100 ]);
        }
        else if(e.key == 'w'){
            focus = 'fft_size';
            cfq = (e) => {
                if(e.key == 'f'){
                    if(h.fft_size == 256) ch2(128);
                    else if(h.fft_size == 512) ch2(256);
                    else if(h.fft_size == 1024) ch2(512);
                    else if(h.fft_size == 2048) ch2(1024);
                }
                else if(e.key == 'j'){
                    if(h.fft_size == 128) ch2(256);
                    else if(h.fft_size == 256) ch2(512);
                    else if(h.fft_size == 512) ch2(1024);
                    else if(h.fft_size == 1024) ch2(2048);
                }
            };
        }
        else if(e.key == 'e'){
            focus = 'frame_time';
            cfq = (e) => {
                console.log(h.frame_time)
                if(e.key == 'f'){
                    if(h.frame_time == .005) ch2(.001);
                    else if(h.frame_time == .01) ch2(.005);
                    else if(h.frame_time == .05) ch2(.01);
                    else if(h.frame_time == .1) ch2(.05);
                }
                else if(e.key == 'j'){
                    if(h.frame_time == .001) ch2(.005);
                    else if(h.frame_time == .005) ch2(.01);
                    else if(h.frame_time == .01) ch2(.05);
                    else if(h.frame_time == .05) ch2(.1);
                }
            };
        }
        else if(e.key == 'r'){
            focus = 'time_step';
            cfq = (e) => {
                console.log(h.time_step)
                if(e.key == 'f'){
                    if(h.time_step == .005) ch2(.001);
                    else if(h.time_step == .01) ch2(.005);
                    else if(h.time_step == .05) ch2(.01);
                    else if(h.time_step == .1) ch2(.05);
                }
                else if(e.key == 'j'){
                    if(h.time_step == .001) ch2(.005);
                    else if(h.time_step == .005) ch2(.01);
                    else if(h.time_step == .01) ch2(.05);
                    else if(h.time_step == .05) ch2(.1);
                }
            };
        }
        else if(e.key.match(/[asdfjkl;]/)){
            cfq(e);
        }
        else{
            focus = null;
        }
    }
    function make_cfq(x){
        const h = {};
        h[`down_${-x[0]}`] = () => ch(x[0]);
        h[`down_${-x[1]}`] = () => ch(x[1]);
        h[`down_${-x[2]}`] = () => ch(x[2]);
        h[`down_${-x[3]}`] = () => ch(x[3]);
        h[`up_${x[4]}`] = () => ch(x[4]);
        h[`up_${x[5]}`] = () => ch(x[5]);
        h[`up_${x[6]}`] = () => ch(x[6]);
        h[`up_${x[7]}`] = () => ch(x[7]);
        return h;
    }
    function make_cfq_map(x){
        return {
            a: `down_${-x[3]}`,
            s: `down_${-x[2]}`,
            d: `down_${-x[1]}`,
            f: `down_${-x[0]}`,
            j: `up_${x[4]}`,
            k: `up_${x[5]}`,
            l: `up_${x[6]}`,
            ';': `up_${x[7]}`,
        };
    }
    let help_screenc;
    let input_screenc;
    // const kb = new Keyboard('settings');
    const list = [];
    const d = {
        get_map: () => map,
        // wave_canvas_height: () => {
        //     focus = 'wave_canvas_height';
        //     const map = make_cfq_map(const1);
        //     const d = make_cfq(const1);
        //     d.get_map = () => map;
        //     opend2(d);
        // },
        height: () => {
            focus = 'height';
            const map = {
                a: 'set_to_100',
                b: 'set_to_200',
                c: 'set_to_300',
                d: 'set_to_400',
                e: 'set_to_500'
            };
            const d = {
                get_map: () => map,
                set_to_100: () => ch2(100),
                set_to_200: () => ch2(200),
                set_to_300: () => ch2(300),
                set_to_400: () => ch2(400),
                set_to_500: () => ch2(500),
            }
            opend2(d);
        },
        fft_size: () => {
            focus = 'fft_size';
            const map = {
                a: 'set_to_128',
                b: 'set_to_256',
                c: 'set_to_512',
                d: 'set_to_1024',
                e: 'set_to_2048'
            };
            const d = {
                get_map: () => map,
                set_to_128: () => ch2(128),
                set_to_256: () => ch2(256),
                set_to_512: () => ch2(512),
                set_to_1024: () => ch2(1024),
                set_to_2048: () => ch2(2048),
            }
            opend2(d);
        },
        frame_time: () => {
            focus = 'frame_time';
            const map = {
                a: 'set_to_1ms',
                b: 'set_to_5ms',
                c: 'set_to_10ms',
                d: 'set_to_50ms',
                e: 'set_to_100ms'
            };
            const d = {
                get_map: () => map,
                set_to_1ms: () => ch2(.001),
                set_to_5ms: () => ch2(.005),
                set_to_10ms: () => ch2(.01),
                set_to_50ms: () => ch2(.05),
                set_to_100ms: () => ch2(.1),
            }
            opend2(d);
        },
        time_step: () => {
            focus = 'time_step';
            const map = {
                a: 'set_to_1ms',
                b: 'set_to_3ms',
                c: 'set_to_5ms',
                d: 'set_to_10ms',
                e: 'set_to_50ms',
                f: 'set_to_100ms'
            };
            const d = {
                get_map: () => map,
                set_to_1ms: () => ch2(.001),
                set_to_3ms: () => ch2(.003),
                set_to_5ms: () => ch2(.005),
                set_to_10ms: () => ch2(.01),
                set_to_50ms: () => ch2(.05),
                set_to_100ms: () => ch2(.1),
            }
            opend2(d);
        }
    }
    const map = {
        a: 'height',
        b: 'fft_size',
        c: 'frame_time',
        d: 'time_step',
        // 'x': 'close'
    }
    export function open(){ opend(d) }
    function opend(d){
        settings = true;
        const hh = {
            // keyboard: kb,
            map: 'delegate',
            delegate: d,
            mini: true,
            remove: true,
            reset: true
        };
        help_screenc.open(hh);
    }
    function opend2(d){
        settings = true;
        const hh = {
            // keyboard: kb,
            map: 'delegate',
            delegate: d,
            mini: true,
            // remove: true,
            // reset: true
        };
        help_screenc.open(hh);
    }
    // let settings = false;
    function refocus(){
        settings = false;
        document.getElementsByClassName('keyboard')[0].focus();
        // let a = active;
        // active = null;
        // setTimeout( () => active = a, 100);
        // focus = true;
    }
    let mini_css = "shadow-xl bg-white border-2 rounded fixed right-80 top-48 opacity-100 z-10";

</script>

<style>
</style>

<HelpScreen bind:this={help_screenc} on:close={refocus} on:none={refocus} />
<MiniScreenInput bind:this={input_screenc} />

{#if settings}
<div class="{mini_css}">
    <div class="grid grid-cols-2 gap-4">
        {#each all as x}
            <div class="{focus == x ? 'bg-red-100': ''}">{x}</div>
            <div>{h[x]}</div>
        {/each}
    </div>
</div>
{/if}
