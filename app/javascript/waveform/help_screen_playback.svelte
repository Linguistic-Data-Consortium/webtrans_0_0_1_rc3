<script>
    import { createEventDispatcher } from 'svelte'
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte'
    import HelpScreenPlaybackHtml from './help_screen_playback_html.svelte'
    let help;
    onMount( () => {
        // keyboard.root_hide();
        help.focus();
    } );
    function keydown(e){
        dispatch('show', null);
    }
</script>

<style>
</style>

<div bind:this={help} tabindex=0 on:keydown={keydown} class="p-4 h-96 overflow-auto">
    <HelpScreenPlaybackHtml />
</div>
