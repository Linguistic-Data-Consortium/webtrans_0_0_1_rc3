<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Spinner from './spinner.svelte'
    export let help;
    export let admin = false;
    let unused = admin;
    // export let project_id;
    // export let project_admin = false;
    // export let project_users;
    // export let goto_task;
    let name;
    export let p;
    
    let columns = [
        [ 'Task', 'task', 'col-2' ],
        [ 'Kit', 'uid', 'col-2' ],
        // [ 'Source', 'source_id', 'col-1' ],
        // [ 'Type', 'type', 'col-1' ],
        [ 'Filename', 'filename', 'col-2' ],
        [ 'Name', 'name', 'col-2' ],
        [ 'State', 'state', 'col-1' ],
        [ 'Last Edited by', 'kit_user', 'col-1' ]
        // [ 'Uploaded By', 'user', 'col-1' ],
    ];
    let object_id;
    let object_index;
    let block;
    function goto(){
        block = true;
        console.log(open_tasks);
        // let id = open_tasks[object_index[object_id].task_id];
        // let kit = kit_index[kit_id];
        // let task_id = kit.task_id;
        // open_kit_uid = open_tasks[task_id];
        // if(open_kit_uid == kit.uid){
        //     open_kit_uid = null;
        // }
        if(allow_goto){
            let pp = getp("/kits_new?goto=" + object_index[object_id].id);
        }
        pp.then( () => window.location = work_paths[selected_task_id] );
    }
    let browse_tasks = [];
    let pp;
    let work_paths = {};
    let open_tasks = {};
    p.then( (x) => {
        for(let y of x[0]){
            if(y.free){
                browse_tasks.push(getp("/tasks/" + y.task_id + "?existing=true"));
                work_paths[y.task_id] = y.work_path;
                if(y.state == 'has_kit'){
                    open_tasks[y.task_id] = y.kit_uid;
                }
                else{
                    open_tasks[y.task_id] = false;
                }
            }
        }
        pp = Promise.all(browse_tasks).then( (a) => {
            let b = [];
            for(let x of a){
                for(let y of x){
                    if(y.source_id){
                        y.type = 'file';
                        y.uid = y.key;
                    }
                    else{
                        y.type = 'kit';
                    }
                }
                b = b.concat(x);
            }
            return b;
        });
    });
    let allow_return;
    let allow_goto;
    let open_kit_uid;
    let selected_task_id;
    $: {
        if(object_id){
            selected_task_id = object_index[object_id].task_id;
            open_kit_uid = open_tasks[selected_task_id];

            // open_kit = open_tasks[object_index[object_id].task_id];
            allow_return = object_index[object_id].uid == open_kit_uid;
            allow_goto =  !open_kit_uid && object_index[object_id].state == 'done';
        }
    }
 </script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>
            This table shows transcripts created by the group, and you can open any one of them,
            as long as it's not already open by someone else.
        </p>
        <p>
            If you have one open, you can return to it here (as well as from the Work tab).
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
                {#if block}
                    <div class="mx-auto w-8 h-8"><Spinner /></div>
                {:else}
                    <button
                        class="{btn}"
                        on:click={goto}
                        disabled={!allow_return && !allow_goto}
                    >
                        {#if allow_return}
                            Return to Transcript
                        {:else if allow_goto}
                            Open Transcript
                        {:else if open_kit_uid}
                            {open_kit_uid} is open
                        {:else}
                            this transcript is open
                        {/if}
                    </button>
                {/if}
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
        <Table bind:selected={object_id} bind:index={object_index} {columns} rows={v} use_filter={true} key_column=uid height=400 />
    {/await}
{/await}
