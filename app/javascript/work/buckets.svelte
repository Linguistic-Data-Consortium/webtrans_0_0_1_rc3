<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Bucket from './bucket.svelte'
    export let help;
    export let admin = false;
    export let lead_annotator = false;
    export let portal_manager = false;
    export let project_manager = false;
    export let p_for_bucket;
    let unused = portal_manager && project_manager;
    let category;
    let name;
    let p;
    function get(){ p = getp('/bucket') }
    get();
    let columns = [
        [ 'Bucket', 'name', 'col-1' ]
    ];
    let flash_type = null;
    let flash_value;
    let bucket_name;
    let bucket_index;
    p.then( (o) => {
			console.log("does this still need to happen?");
			console.log(o);
    });
    let bucket;
    let style;
    let timeout;
    function selected(e){
        style = `position: absolute; left: ${e.detail.pageX-20}px; top: ${e.detail.pageY+20}px; z-index: 10`;
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout( () => style = null, 2000);
    }
</script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>features</p>
    </div>
</Help>

{#await p}
    loading...
{:then v}
    {#if bucket}
        <div class="flexx justifxy-around">
            <div class="float-right">
                <button class="{btn}" on:click={()=>bucket=null}>Return to Bucket list</button>
            </div>
        </div>
        <Bucket {help} {admin} {lead_annotator} {bucket} {p_for_bucket} />
    {:else}
        <div class="w-1/2 mx-auto">
            <div class="flex justify-around">
                <div>
                    <button class="{btn}" on:click={()=>bucket=bucket_name}>Open</button>
                </div>
            </div>
            {#if style}
                <div {style}>
                    <div class="p-1"><button class="{btn}" on:click={()=>bucket=bucket_name}>Open</button></div>
                </div>
            {/if}
            <Table bind:selected={bucket_name} bind:index={bucket_index} {columns} rows={v.buckets} use_filter={true} key_column=name height=96 on:selected={selected} />
        </div>
    {/if}
{/await}
