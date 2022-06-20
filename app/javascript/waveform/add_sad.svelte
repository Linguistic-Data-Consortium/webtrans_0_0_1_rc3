<script>
    import { onMount, createEventDispatcher, tick } from 'svelte'
    const dispatch = createEventDispatcher();
    import Spinner from '../work/spinner.svelte'
    import { add_sad, check_channels, add_timestamps } from '../work/services'
    let help;
    onMount( () => {
        // keyboard.root_hide();
        help.focus();
        console.log('key')
    } );
    function keydown(e){
    //     dispatch('show', null);
    }
    let p = add_sad();
    let p2 = p.then( (url) => {
        const o = { type: 'sad', data: { audio: url } };
        return ldc_services.sad(o, function(data) {
            return check_channels(data);
        } );
    } );
    let p3 = p2.then( (data) => {
        console.log('adding')
        console.log(data);
        const f = add_timestamps(data);
        f();
        ldc_annotate.add_callback( () => dispatch('show', null) );
        return 'displaying segments...';
    } );
</script>

<style>
</style>

<div bind:this={help} tabindex=0 on:keydown={keydown} class="p-4 h-96 overflow-auto">
    <div class="w-full mx-auto">
        {#await p}
            <Spinner />
            prep sad...
        {:then v}
            <!-- adding {v.length} segments -->
            using {v}
        {:catch e}
            <div>error</div>
            <div>{e}</div>
        {/await}
        <hr>
        {#await p2}
            <Spinner />
            running sad...
        {:then v}
            <div> adding {v.ch1.length} segments from channel 1</div>
            {#if v.ch2.length}
                <div> adding {v.ch2.length} segments from channel 2</div>
            {/if}
        {:catch e}
            <div>error</div>
            <div>{e}</div>
        {/await}
        <hr>
        {#await p3}
            <Spinner />
            creating segments...
        {:then v}
            <Spinner />
            <div>{v}</div>
        {:catch e}
            <div>error</div>
            <div>{e}</div>
        {/await}
    </div>
</div>
