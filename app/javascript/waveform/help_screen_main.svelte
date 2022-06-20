<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte';
    // export let waveform;
    // export let help_screen;
    export let keyboard;
    export let close;
    const a = [
        'Waveform',
        'Text Input',
        'Playback',
        'Services',
        'Open Guidelines'
    ];
    let help;
    onMount( () => {
        // keyboard.root_hide();
        help.focus();
    } );
    let keys = {
        "1": "show_help_screen_waveform",
        "2": "show_help_screen_input",
        "3": "show_help_screen_playback",
        // # "4": "show_help_screen_edit",
        "4": "show_help_screen_services",
        "5": "open_guidelines",
        '/': 'special_settings'
    }
    keyboard.map = keys;
    function keydown(e){
        if(Object.keys(keys).includes(e.key)){
            // waveform.upload_transcript();
            // keyboard.reset();
            dispatch('show', keys[e.key]);
        }
        else{
            keyboard.handle(e);
            dispatch('show', null);
        }
        // close();
    }
</script>

<style>
</style>

<div bind:this={help} tabindex=0 on:keydown={keydown} class="p-4">
    <div class="mb-4 ">
        <p>
            When numbered lists appear, pressing the given number makes the given choice.
            Pressing a key that does not correspond to a valid choice will return to the
            waveform, as well as indicate "unknown choice" in the upper right corner.
        </p>
    </div>
    <div>
        <div class="flex justify-around">
            {#each a as x, i}
                <div>{i+1}. {x}</div>
            {/each}
        </div>
    </div>
</div>
