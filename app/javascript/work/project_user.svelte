<script>
    import { tick } from 'svelte';
    import { getp, postp, deletep, patchp } from "./getp";
    import Flash from './flash.svelte'
    import Spinner from './spinner.svelte'
    export let id;
    export let is_owner;
    export let is_admin;
    let p;
    let flash_type;
    let flash_value;
    let timeout;
    let first = true;
    function update(x){
        if(first){
            // first = false;
            return;
        }
        patchp(
            `/project_users/${id}`,
            x
        ).then(
            function(data){
                if(data.error){
                    flash_type = 'error';
                    flash_value = data.error.join(' ');
                }
                else{
                    flash_type = 'success';
                    flash_value = data.ok;
                }
            }
        );
    }
    $: update({ owner: is_owner });
    $: update({ admin: is_admin });
    tick().then( () => first = false );
</script>

<style>
</style>

<Flash {flash_type} {flash_value} />
{#if p}
    {#await p}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {/await}
{/if}
<div>
    <form>
        <label>
            <input type=checkbox bind:checked={is_owner}/>
            Owner
       </label>
        <label>
            <input type=checkbox bind:checked={is_admin}/>
            Admin
       </label>
    </form>
</div>
