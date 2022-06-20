<script>
    import { createEventDispatcher } from 'svelte'
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte'
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
<div>When the text input box is focused, the following bindings work.</div>

<ol>
<li>
- <b>enter</b> jump to next line and play
</li>
<li>
- <b>control-space</b> play current span
</li>
<li>
- <b>control-d</b> delete current line
</li>
<li>
- <b>control-m</b> merge active segment with the following segment
</li>
<li>
- <b>control-,</b> split active segment at the cursor
</li>
</ol>
</div>
