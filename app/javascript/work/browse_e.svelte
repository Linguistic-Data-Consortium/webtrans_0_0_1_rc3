<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Table from './table.svelte'
    import Spinner from './spinner.svelte'
    export let tasks;
    let all = [];
    let open_tasks = {};
    let work_paths = {}
    for(let x of tasks){
        all.push(getp("/tasks/" + x.task_id + "?existing=true"));
        if(x.state == 'has_kit'){
            open_tasks[x.task_id] = x.kit_uid;
        }
        else{
            open_tasks[x.task_id] = false;
        }
        work_paths[x.task_id] = x.work_path;
    }
    let p = Promise.all(all).then((a) => {
        let aa = [];
        for(let x of a){
            aa = aa.concat(x);
        }
        return aa;
    });
    let columns = [
        // [ 'Type', 'type', 'col-1' ],
        [ 'Filename', 'done_comment', 'col-1' ]
        // [ 'Location', 'location', 'col-1' ],
        // [ 'Key', 'key', 'col-1' ],
        // [ 'Action', 'action', 'col-1' ]
    ];
    let kit_id;
    let kit_index;
    let pp;
    let open_kit_uid;
    function open_kit(){
        let kit = kit_index[kit_id];
        let task_id = kit.task_id;
        open_kit_uid = open_tasks[task_id];
        if(open_kit_uid == kit.uid){
            open_kit_uid = null;
        }
        if(!open_kit_uid){
            pp = getp("/kits_new?goto=" + kit_id);
            pp.then( () => window.location = work_paths[task_id] );
        }
    }
    function return_to_kit(){
        let id;
        for(let x in kit_index){
            if(kit_index[x].uid == open_kit_uid){
                id = x;
                break;
            }
        }
        if(id){
            kit_id = id;
            open_kit();
        }
        else{
            alert("error, kit missing from list");
        }
    }
</script>

<style>
</style>

<div>
    {#await p}
        <div>searching transcripts</div>
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then rows}
        {#if kit_id}
            {#if pp}
                {#await pp}
                    opening
                {:then v}
                    <div> opening {v.ok.uid} {v.ok.done_comment}</div>
                    <div class="mx-auto w-8 h-8"><Spinner /></div>
                {/await}
            {:else if open_kit_uid}
                <div>
                    You can't open the selected kit because another kit in the same task
                    is already open.  You need to close that kit before opening another
                    in the same task.
                </div>
                <div><button class="{btn}" on:click={return_to_kit}>Return to open kit</button></div>
                <div><button class="{btn}" on:click={() => open_kit_uid = null}>Show list of kits</button></div>
            {:else}
                <div>selected kit {kit_index[kit_id].uid}</div>
                <div>with file {kit_index[kit_id].done_comment}</div>
                <div><button class="{btn}" on:click={open_kit}>Open</button></div>
                <!-- <div>selected {JSON.stringify(kit_index[kit_id])}</div> -->
            {/if}
        {/if}
        {#if !open_kit_uid}
            <Table bind:selected={kit_id} bind:index={kit_index} {columns} {rows} use_filter={true} key_column=id height=400 />
        {/if}
    {/await}
</div>
