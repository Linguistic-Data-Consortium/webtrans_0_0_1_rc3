<script>
    import { getp, postp, deletep, patchp } from "./getp";
    import Table from './table.svelte'
    import BrowseC from './browse_c.svelte';
    import BrowseD from './browse_d.svelte';
    import BrowseE from './browse_e.svelte';
    import InputSelect from './input_select.svelte';
    export let sel2;
    export let sel3;
    export let browser;
    export let tasks;
    export let tasksp;
    let hidden1 = false;
    let hidden11 = true;
    let hidden2 = true;
    let hidden22 = true;
    let hidden3 = true;
    let hidden4 = true;
    let hidden5 = true;
    let hidden55 = true;
    let nfiles = 0;
    let bucket = 'speechbiomarkers';
    let nfiles_in_bucket = 0;
    let nkits = 0;
    let search_for = [];
    // export function step1(){
    //     hidden1 = false;
    //     // browser.browse();
    // }
    // export function step2(n){
    //     hidden2 = false;
    //     nfiles = n;
    // }
    // export function step4(n){
    //     hidden4 = false;
    //     nfiles_in_bucket = n;
    // }
    export function step5(n){
        hidden5 = false;
        nkits = n;
    }
    let dbp;
    function search(){
        // if(search_for.length == 0){
        //     alert("nothing selected")
        //     return;
        // }
        hidden11 = false;
        hidden1 = true;
        const h = {
            search_for: search_for
        }
        browser.browse(h);
    }
    let columns = [
        [ 'Type', 'type', 'col-1' ],
        [ 'Filename', 'filename', 'col-1' ],
        [ 'Location', 'location', 'col-1' ],
        [ 'Key', 'key', 'col-1' ],
        [ 'Action', 'action', 'col-1' ]
    ]
    let task_id;
</script>

<style>
    /* .hidden1, .hidden11,
    .hidden2, .hidden22,
    .hidden3,
    .hidden4,
    .hidden5, .hidden55 {
        visibility: hidden;
    } */
</style>

{#await tasksp}
    loading...
{:then v}
    <!-- {JSON.stringify(v[0])} -->
    {#if v[0].length}
        <div>Upload into one of these tasks</div>
        <label for=x>Project/Task</label>
        <select id=x class="form-select" bind:value={task_id}>
            <option value={null}></option>
            {#each v[0] as task}
                {#if task.free}
                    <option value={task.task_id}>
                        {task.project} / {task.task}
                    </option>
                {/if}
            {/each}
        </select>
    {:else}
        <div>No tasks are available for upload</div>
    {/if}
{/await}


<BrowseC {tasks} />

<div class="flex justify-around">
    <div class="float-left col-4">
    </div>
    <div class="float-left col-4">
        <!-- <BrowseD {browser} bucket={tasks[0].bucket} /> -->
        <!-- <BrowseD {browser} bucket={bucket} /> -->
        search buckets (under construction)
    </div>
    <div class="float-left col-4">
        <!-- <BrowseE task_id={tasks[0].task_id}/> -->
        <!-- <BrowseE {tasks} /> -->
    </div>
</div>

    <div class={sel2} class:hidden11 >
        <div>
        </div>
        <hr>
        <div>The following list contains both audio files and transcripts.</div>
        <div>Click New for a new transcript, or Open for an existing one.</div>
        <hr>
        <div id={sel3}>
            <div>loading...</div>
        </div>
    </div>
