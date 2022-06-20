<script>
    import { tick } from 'svelte';
    import { patchp } from './getp'
    export let label;
    export let key;
    export let value;
    export let url;
    export let meta;
    export let disabled = false;
    const id = Math.random().toString(36).substring(2);
    let flash_type;
    let flash_value;
    let flash_css;
    function patch(k, v){
        if(!url){
            return;
        }
        let x = {};
        if(meta == 'meta'){
            x.meta = {};
            x.meta[k] = v;
        }
        else if(meta == 'constraints'){
            x.constraints = {};
            x.constraints[k] = v;
        }
        else{
            x[k] = k;
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
                    console.log(data)
                    flash_value = "updated " + k + " to " + (data[k] || (data.meta && data.meta[k]) || (data.constraints && data.constraints[k]));
                    setTimeout( () => flash_type = null, 2000);
                }
            }
        );
    }
    let first = true;
    function update(x){
        if(first){
            return;
        }
        patch( key, value );
    }
    $: update(value);
    tick().then( () => first = false );
</script>

<style>
input { display: inline-block; }
</style>

<div class="{flash_type ? flash_type + "ed" : ''}">
    <div>
        <label for="input-{id}">
            <input
                id="input-{id}"
                class="focus:ring-indigo-500 focus:border-indigo-500 h-4 w-4 border-gray-300"
                type="checkbox"
                bind:checked={value}
                aria-describedby="input-{id}-validation"
                {disabled}
            />
            {label}
        </label>
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
