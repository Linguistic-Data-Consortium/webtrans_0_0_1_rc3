<script>
    import { createEventDispatcher } from 'svelte'
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte'
    let help;
    onMount( () => {
        // keyboard.root_hide();
        help.focus();
    } );
    let keys = {
    }
    function keydown(e){
        if(Object.keys(keys).includes(e.key))
            dispatch('service', keys[e.key]);
        else
            dispatch('show', null);
    }
</script>

<style>
</style>

<div bind:this={help} tabindex=0 on:keydown={keydown} class="p-4 h-96 overflow-auto">
<ol>
<li>
unavailable
</li>
</ol>
</div>
