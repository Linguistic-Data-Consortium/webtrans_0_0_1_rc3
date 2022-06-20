<script>
    import { tick } from 'svelte';
    import { getp, postp, deletep, patchp } from "./getp";
    import Table from './table.svelte'
    import Modal from './modall.svelte'
    import Flash from './flash.svelte'
    // export let admin = false;
    // export let lead_annotator = false;
    export let class_def_id;

    export let id;
    export let name;

    let p;
    let flash_type = null;
    let flash_value;
    let timeout;
    let first = true;
    function update(x){
        if(first){
            // first = false;
            return;
        }
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout(() => {
            patchp(
                `/class_defs/${class_def_id}`,
                { name: name }
            ).then(
                function(data){
                    if(data.error){
                        flash_type = 'error';
                        flash_value = data.error.join(' ');
                    }
                    else{
                        flash_type = 'success';
                        flash_value = "updated " + data.class_def.name;
                    }
                }
            );
        }, 1000);
    }
    $: update(name);
    tick().then( () => first = false );
</script>

<style>
</style>

<Flash {flash_type} {flash_value} />
<div class="col-3 mx-auto">
    <div>ID: {id}</div>
    <form>
        <label>
            Name
            <input type=text bind:value={name}/>
        </label>
    </form>
</div>
