<script>
    import { tick } from 'svelte';
    export let label;
    export let key;
    export let value;
    export let url;
    export let meta;
    export let wrap;
    const id = Math.random().toString(36).substring(2);
    let flash_type;
    let flash_value;
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
                }
                else{
                    flash_type = 'success';
                    console.log(data)
                    flash_value = "updated " + k + " to " + (data[k] || (data.meta && data.meta[k]) || (data.constraints && data.constraints[k]));
                }
            }
        );
    }
    patch( key, value );
</script>

<div class="form-group {flash_type ? flash_type + "ed" : ''}">
    <div class="form-group-header">
        <label for="input-{id}">
            {label}
        </label>
        {#if flash_type}
            <p id="input-{id}-validation" class="note {flash_type}">{flash_value}</p>
        {/if}
    </div>
</div>
