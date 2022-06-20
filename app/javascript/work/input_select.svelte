<script>
    import { tick } from 'svelte';
    import { patchp } from './getp'
    export let url;
    export let label;
    export let key;
    export let value;
    export let values;
    export let att = false;
    export let idk = 'id';
    export let meta = false;
    let flash_type;
    let flash_value;
    let flash_css;
    const id = Math.random().toString(36).substring(2);
    function patch(k, v){
        if(!url){
            return;
        }
        let x = {};
        if(att){
            if(meta){
                x.meta = {};
                if(v[idk] == 0){
                    x.meta[k] = '';
                }
                else{
                    x.meta[k] = v[idk];
                }
            }
            else{
                x[k] = v[idk];
            }
        }
        else{
            if(meta){
                x.meta = {};
                x.meta[k] = v;
            }
            else{
                x[k] = v;
            }
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
                    flash_value = "updated " + k + " to " + (data[k] || (data.meta && data.meta[k]));
                    setTimeout( () => flash_type = null, 2000);
                }
            }
        );
    }
    let first = true;
    function update(x){
        // alert('update ' + key + ' ' + JSON.stringify(value));
        if(first){
            return;
        }
        patch( key, value );
    }
    $: update(value);
    tick().then( () => first = false );
</script>

<div class="form-group {flash_type ? flash_type + "ed" : ''}">
    <div class="form-group-header">
        <label for="input-{id}">{label}</label>
    </div>
    <div class="form-group-body">
        <select
            id="input-{id}"
            class="focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
            bind:value={value}
            aria-describedby="input-{id}-validation"
        >
            {#each values as x}
                <option value={x}>{att ? x[att] : x}</option>
            {/each}
        </select>
        {#if flash_type}
            <p id="input-{id}-validation"
                class="{flash_css}"
                on:click={ () => flash_type = null }
            >
                {flash_value}
            </p>
        {/if}
    </div>
</div>
