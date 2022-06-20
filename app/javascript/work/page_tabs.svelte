<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    export let pages;
    export let page = 1;
    export let admin = false;
    export let lead_annotator = false;
    export let help;
</script>

<style>
</style>

<div class="mb-4 max-w-full overflow-auto">
    <nav class="flex" aria-label="Foo bar">
        {#each pages as x, i}
            {#if
                x[1] == 'all' ||
                (x[1] == 'lead_annotator' && lead_annotator) ||
                (x[1] == 'admin' && admin)
            }
                <div class="{page==i+1 ? 'border-t border-l border-r rounded-t-md bg-gray-50' : 'border-b'} px-4 py-2" aria-current={page==i+1} on:click={() => dispatch('page', i+1)}>
                    <div class="whitespace-nowrap text-sm text-gray-700">{x[0]}</div>
                    {#if help}
                        <div class="bg-blue-200 rounded p-1">{x[2]}</div>
                        <!-- <button class="btn btn-small" on:click={() => dispatch('help', i+1)}><i class="fa fa-question"></i></button> -->
                    {/if}
                </div>
            {/if}
        {/each}
    </nav>
</div>
