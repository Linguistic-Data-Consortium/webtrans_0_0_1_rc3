<script>
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte';
    import { getp, postp, deletep, patchp } from "./getp";
    export let node_id;
    export let name;
    export let label;
    export let key;
    // export let value;
    export let textarea;
    export let disabled;
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
        tick().then( () => first = false );
        tick().then( () => dispatch('init', value) );
    });
    const id = Math.random().toString(36).substring(2);
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
</script>

<div class={`form-group ${name}Box`}>
    <div class={`form-group-header ${name}Label`}>
        <label for="input-{id}">{label}</label>
    </div>
    <div class={`form-group-body ${name}`}>
        {#if textarea}
            <textarea
                id="input-{id}"
                class="focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                bind:value={value}
                aria-describedby="input-{id}-validation"
                on:blur={blur}
            />
        {:else}
            <input
                id="input-{id}"
                class="focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                type=text
                bind:value={value}
                aria-describedby="input-{id}-validation"
                {disabled}
                on:blur={blur}
            />
        {/if}
    </div>
</div>
