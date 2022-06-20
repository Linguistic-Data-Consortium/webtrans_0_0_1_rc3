<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Table from './table.svelte'
    import Spinner from './spinner.svelte'
    export let tasks;
    let p;
    let all = [];
    let work_paths = {};
    for(let x of tasks){
        all.push(getp("/browser?blobs=audio&task_id=" + x.task_id));
        work_paths[x.task_id] = x.work_path;
    }
    p = Promise.all(all).then( (values) => {
        let r = [];
        for(let x of values){
            r = r.concat(x);
        }
        return r;
    })
    // p.then(function(data){
    //     nfiles = data.length;
    //     for(let x of data){
    //         rows.push({
    //             type: 'audio',
    //             location: 'db',
    //             source_id: x.source_id,
    //             filename: x.filename,
    //             key: x.key
    //         })
    //     }
    //     rows = rows;
    // });
    let columns = [
        // [ 'Source', 'source_id', 'col-1' ],
        [ 'Filename', 'filename', 'col-3' ]
        // [ 'Key', 'key', 'col-1' ]
    ]
    let source_id;
    let source_index;
    let pp;
    function open(){
    // $(that.sel2).on 'click', '.new, .news3', ->
        // if $(this).hasClass('news3')
        //     copen = 's3'
        //     source = $(this).data().key
        // else
        //     copen = 'open'
        //     source = $(this).attr('class').split(' ')[1]
        let copen = 'open';
        let path = `/kits_new?${copen}=${source_id}&task_id=${source_index[source_id].task_id}&filename=${source_index[source_id].filename}`
        pp = getp(path);
        pp.then( () => window.location = work_paths[source_index[source_id].task_id] ); 
    }
</script>

<style>
</style>


{#if pp}
    {#await pp}
        opening
    {:then v}
        <div> opening {v.ok.source_uid}</div>
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {/await}
{:else}
    {#if source_id}
        <div><button class="{btn}" on:click={open}>Open</button></div>
    {/if}
    {#await p}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then rows}
        <Table bind:selected={source_id} bind:index={source_index} {columns} {rows} use_filter={true} key_column=source_id height=500 />
    {/await}
{/if}
