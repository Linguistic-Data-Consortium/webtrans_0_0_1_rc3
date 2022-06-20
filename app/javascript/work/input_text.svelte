<script>
    import { tick } from 'svelte';
    import { patchp } from './getp'
    export let label;
    export let key;
    export let value = null;
    export let textarea = false;
    export let url = false;
    export let meta = false;
    export let wrap = false;
    export let required = false;
    export let split = null;
    let unused = required;
    if(split && value) value = value.join(split);
    let flash_type;
    let flash_value;
    let flash_css;
    const id = Math.random().toString(36).substring(2);
    function patch(k, v){
        if(!url){
            return;
        }
        let x = {};
        if(split){
            v = v.split(split);
        }
        if(meta == 'meta'){
            x.meta = {};
            x.meta[k] = v;
        }
        if(meta == 'constraints'){
            x.constraints = {};
            x.constraints[k] = v;
        }
        else{
            x[k] = v;
        }
        if(wrap){
            const y = {};
            y[wrap] = x;
            x = y;
        }
        patchp( url, x ).then(
            function(data){
                if(data.error){
                    flash_type = 'error';
                    flash_value = data.error.join(' ');
                    flash_css = "bg-red-100 border-red-400 text-red-700 px-4 py-3 rounded-full";
                }
                else{
                    flash_type = 'success';
                    flash_css = "bg-green-100 border-green-400 text-green-700 px-4 py-3 rounded-full";
                    flash_value = "updated " + k + " to " + (data[k] || (data.meta && data.meta[k]) || (data.constraints && data.constraints[k]));
                    setTimeout( () => flash_type = null, 2000);
                }
            }
        );
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
        timeout = setTimeout( () => patch( key, value ) , 1000 );
    }
    $: update(value);
    tick().then( () => first = false );
</script>

<div class="pb-4 {flash_type ? flash_type + "ed" : ''}">
    <div class="form-group-header">
        <label for="input-{id}">{label}</label>
    </div>
    <div class="form-group-body">
        {#if textarea}
            <textarea
                id="input-{id}"
                class="focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                bind:value={value}
                aria-describedby="input-{id}-validation"
            />
        {:else}
            <input
                id="input-{id}"
                class="focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                type=text
                bind:value={value}
                aria-describedby="input-{id}-validation"
            />
        {/if}
        {#if flash_type}
            <p
                id="input-{id}-validation"
                class="{flash_css}"
                on:click={ () => flash_type = null }
            >
                {flash_value}
            </p>
        {/if}
    </div>
</div>
