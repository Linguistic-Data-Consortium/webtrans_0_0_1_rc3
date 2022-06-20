<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import HelpScreenPlaybackHtml from '../waveform/help_screen_playback_html.svelte'
    import { fmap2 } from '../work/keyboard_helper'
    let hidden = true;
    let mini;
    let input;
    let list = [];
    let title = 'TITLE'
    let keyboard;
    let unknown_key_callback;
    let remove;
    let reset;
    let html;
    let screen;
    let map;
    let delegate;
    export function open(h){
        hidden = false;
        title = h.title;
        keyboard = h.keyboard;
        list = h.list;
        remove = h.remove;
        reset = h.reset;
        html = h.html;
        mini = h.mini;
        map = h.map;
        delegate = h.delegate;
        if(map == 'delegate' && !list){
            map = delegate.get_map();
            list = [];
            for(let k in map) list.push([k, map[k]]);
        }
        if(!mini){
            keyboard.root_hide();
        }
        setTimeout(function(){
            screen.focus();
        }, 100);
    }
    function keydown(e){
        e.preventDefault();
        if(remove){
            hidden = true;
        }
        if(reset){
            // keyboard.reset()
            dispatch('close');
        }
        if(keyboard){
            const f = keyboard.handle(e, mini);
            if(f === 'close') hidden = true;
        }
        else{
            const userf = fmap2(false, delegate, e, map);
            // console.log(userf)
            if(userf){
                // dispatch('userf', { userf: userf, e: e } )
                if(userf === 'close') hidden = true;
                if(userf === 'none'){
                    hidden = true;
                    dispatch('none');
                }
            }
        }
    }
    let mini_css = "shadow-xl bg-white border-2 rounded fixed right-24 top-48 opacity-100 z-10";
</script>

<style>
</style>


<div bind:this={screen} class="p-2 {mini ? mini_css : ''}" class:hidden tabindex=0 on:keydown={keydown}>
    <div>
        {#if html}
            {#if html == 'help_screen_playback_html'}
                <HelpScreenPlaybackHtml />
            {:else}
                {@html html}
            {/if}
        {:else}
           <div>
                {#if title}
                    <h3 class="text-xl mb-1">{title}</h3>
                {/if}
                <ul>
                    {#each list as x}
                        <li class="mb-1"><span class="font-sans font-semibold uppercase text-gray-300">{x[0]}</span> {x[1]}</li>
                    {/each}
                </ul>
                <div class="text-xs">press any other key to exit</div>
            </div>
        {/if}
    </div>
</div>
