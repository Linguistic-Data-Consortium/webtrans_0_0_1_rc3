<script>
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep, patchp } from "./getp";
    import Flash from './flash.svelte'
    import Spinner from './spinner.svelte'
    export let id;
    export let is_admin;
    export let state;
    let states = [ null, 'needs_kit', 'has_kit', 'hold', 'paused' ];
    let p = getp(`/task_users/${id}`);
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
            `/task_users/${id}`,
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
                setTimeout( () => dispatch('reload', '') , 1000 );
            }
        );
    }
    $: update({ admin: is_admin });
    $: update({ state: state });
    tick().then( () => first = false );
</script>

<style>
</style>

<Flash {flash_type} {flash_value} />
<div>
    <form>
        <label>
            <input type=checkbox bind:checked={is_admin}/>
            Admin
       </label>
        <label for=x>
            State
            {#if states.includes(state)}
                <select id="x" bind:value={state}>
                    {#each states as x}
                        <option value={x}>{x}</option>
                    {/each}
                </select>
            {:else}
                Error
            {/if}
        </label>
    </form>
    <div class="my-4">
        {#if p}
            {#await p}
                <div class="mx-auto w-8 h-8"><Spinner /></div>
            {:then v}
                <pre>
                    {v.ok}
                </pre>
            {/await}
        {/if}
    </div>
</div>
