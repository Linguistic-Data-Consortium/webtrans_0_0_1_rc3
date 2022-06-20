<script>
    import { onMount } from 'svelte'
    import { createEventDispatcher } from 'svelte'
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './tablem.svelte'
    import Modal from '../modal.svelte'
    import Flash from './flash.svelte'
    import Kit from './kit.svelte'
    export let help;
    export let project_id;
    export let task_id;
    export let task_admin = false;
    // export let kits;
    export let task_users;
    let should_use = project_id && task_admin && task_users;
    export let meta;
    let name;
    let p;
    function get(){ p = getp(`/kits/task/${task_id}`) }
    get();
    
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'UID', 'uid', 'col-1', 'f', (x, y) => window.open(x.link) ],
        [ 'State', 'state', 'col-1', 'filter' ],
        [ 'Source', 'source_uid', 'col-1' ],
        [ 'User', 'user', 'col-1', 'filter' ],
        [ 'Dual', 'dual_id', 'col-1' ]
    ];
    let kit_id;
    let kit_index;
    let table;
    let ndual = 0;
    let nnondual = 0;
    let ntotal = 0;
    let nshould = 0;
    let nduration = 0;
    let min;
    if(meta.dual_minimum_duration) min = Number(meta.dual_minimum_duration);
    let interval = setInterval( () => {
        if(typeof(kit_index) == 'object') clearInterval(interval);
        else return;
        console.log(kit_index)
        for(let [k, v] of kit_index){
            ntotal += 1;
            if(v.dual_id) ndual += 1;
            else{
                if(min && v.duration > min) nduration += 1;
                else                        nnondual += 1;
            }
        }
        nshould = ntotal * Number(meta.dual_percentage) / 100.0;
    }, 1000 );
 </script>

<style>
</style>

{#await p}
    loading...
{:then rows}
    <div>{ntotal} kits total</div>
    <!-- <div>{nshould} will be duals</div> -->
    {#if min}
        <div>{ndual} of possible {nduration} are duals ({(ndual/nduration*100).toPrecision(4)} percent)</div>
        <div>{nduration} are long enough</div>
    {:else}
        <div>{ndual} of possible {nnondual} are duals ({(ndual/nnondual*100).toPrecision(4)} percent)</div>
    {/if}
    <hr>
    <Help {help}>
        <div slot=content>
            <p>The table can be filtered by user, state, and text (which matches any column)</p>
            <p>The filters are conjoined (all must be true)</p>
            <p>The Bulk Reassign feature depends on these filters; the filters select the kits to be reassigned</p>
        </div>
    </Help>
    <Table
        bind:this={table}
        bind:selected={kit_id}
        bind:index={kit_index}
        {columns}
        {rows}
        use_filter={true}
        key_column=id
        height=400
        download={true}
    />
 {/await}
