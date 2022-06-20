<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Spinner from './spinner.svelte'
    import { get_open_tasks } from './browse_helper'
    export let help;
    export let admin;
    let unused = admin;
    // export let project_id;
    // export let project_admin = false;
    // export let project_users;
    // export let goto_task;
    let name;
    export let p;
    
    let columns = [
        [ 'Task', 'task', 'col-2' ],
        // [ 'Source', 'source_id', 'col-1' ],
        // [ 'Type', 'type', 'col-1' ],
        [ 'Filename', 'filename', 'col-3' ],
        // [ 'Key', 'key', 'col-2' ],
        // [ 'Last Edited by', 'kit_user', 'col-1' ],
        [ 'Uploaded By', 'user', 'col-1' ]
    ];
    let object_id;
    let object_index;
    function create(){
    // $(that.sel2).on 'click', '.new, .news3', ->
        // if $(this).hasClass('news3')
        //     copen = 's3'
        //     source = $(this).data().key
        // else
        //     copen = 'open'
        //     source = $(this).attr('class').split(' ')[1]
        console.log(object_index);
        let copen = 'open';
        let path = `/kits_new?${copen}=${object_index[object_id].source_id}&task_id=${object_index[object_id].task_id}&filename=${object_index[object_id].filename}`
        let pp = getp(path);
        // console.log(path);
        pp.then( () => window.location = open_tasks[selected_task_id].work_path ); 
        // pp.then( (data) => console.log(data) ); 
        p = new Promise((x,y) => 1);
    }
    let open_tasks = {};
    let pp = p.then( (x) => get_open_tasks(x, open_tasks) );
    let open_kit_uid;
    let selected_task_id;
    $: {
        if(object_id){
            selected_task_id = object_index[object_id].task_id;
            open_kit_uid = open_tasks[selected_task_id].has_kit;
        }
    }
 </script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>
            If you're a member of a browesable task, this table shows all the uploaded audio files (uploaded by you or by others).
        </p>
        <p>
            You can create a new transcript from any of these audio files, as long as you don't already
            have an open transcript in that task.
        </p>
    </div>
</Help>

{#await p}
    <div class="mx-auto w-8 h-8"><Spinner /></div>
{:then vv}
    <!-- {JSON.stringify(vv)} -->
    <div class="flex justify-around">
        <div>Tasks with Uploaded Files</div>
        {#if object_id}
            <div>
                <button
                    class="{btn}"
                    on:click={create}
                    disabled={open_kit_uid ? true : false}
                >
                    Create Transcript
                    {#if open_kit_uid}
                        (disabled because transcript {open_kit_uid} is open)
                    {/if}
                </button>
            </div>
        {/if}
    </div>
    {#await pp}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then v}
        <!-- {JSON.stringify(v)} -->
        <div class="float-right p-2">
            <!-- {v.name} {object_id} -->
        </div>
        <Table bind:selected={object_id} bind:index={object_index} {columns} rows={v} use_filter={true} key_column=uid height="96" />
    {/await}
{/await}
