<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { createEventDispatcher } from 'svelte'
    import Spinner from './spinner.svelte'
    const dispatch = createEventDispatcher();
    export let partial;
    export let key;
    export let value;
    export let label;
    let pp;
    let path = "/sources/get_upload";
    if(partial){
        path += `?partial=${partial}`
    }
    if(key){
        path += `&${key}=${value}`;
    }
    pp = getp(path);
    pp.then( () => dispatch('sourcefile', '') );
</script>

<style>
</style>

<details>
    <summary class="{btn}">
        {#if label}
            {label}
        {:else}
            Upload / Preview
        {/if}
    </summary>
    <div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="m-3">
                {@html v.html}
            </div>
        {/await}
    </div>
</details>
