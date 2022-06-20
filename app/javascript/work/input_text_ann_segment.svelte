<script>
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte';
    import { getp, postp, deletep, patchp } from "./getp";
    import { fmap_helper } from './keyboard_helper'
    import { x as map } from '../waveform/keys_input'
    export let node_id;
    export let name;
    export let key = null;
    export let disabled = false;
    export let readonly;
    export let readonly_text;
    export let focus;
    export let waveform;
    let sel = `#node-${node_id} .${name}`;
    let value;
    let iid;
    onMount(() => {
        let o = {
            node_id: node_id,
            name: name,
            value: value,
            change: change
        };
        dispatch('set_entry', o);
    });
    ldc_nodes.wait_for(sel, () => {
        let d = window.gdata(sel);
        iid = d.meta.id;
        value = d.value;        
        if(value){
            value = value.value;
        };
        if(readonly) value = readonly_text;
        if(readonly) console.log('readonly ' + readonly_text);
        tick().then( () => first = false );
        tick().then( () => dispatch('init', value) );
    });
    function patch(k, v, e){
        if(timeout) timeout = false;
        ldc_annotate.add_message(iid, 'change', { value: value });
        ldc_annotate.submit_form();
        ldc_annotate.add_callback( () => dispatch(e, value) );
    }
    let first = true;
    let timeout;
    function update(x){
        if(first){
            return;
        }
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout( () => patch( key, value, 'changelite' ) , 1000 );
    }
    $: update(value);
    export function change(v){
        value = v;
    }
    // tick().then( () => first = false );
    function blur(){
        if(timeout){
            clearTimeout(timeout);
            patch( key, value, 'change' );
        }
    }
    function keydown(e){
        const userf = fmap_helper(false, waveform, e, map);
        if(userf){
            dispatch('userf', { userf: userf, e: e } )
        }
    }
    function init(x){
        if(focus) x.focus();
    }
    if(readonly) value = readonly_text;
</script>

<style>
    input {
        border-width: 0px;
        border: none;
    }
</style>

<input
    class="ann-segment pl-1 p-0 w-full text-sm focus:ring-2 focus:ring-red-500 flex-1 block rounded"
    type=text
    bind:value={value}
    {disabled}
    {readonly}
    on:blur={blur}
    on:keydown={keydown}
    use:init
/>
