<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Modal from './modall.svelte'
    import Flash from './flash.svelte'
    import InputUpload from './input_upload.svelte'
    import Spinner from './spinner.svelte'
    // export let help;
    export let data_set_id;
    // export let project_owner = false;
    export let assets;
    let name;
    let title;
    let description;
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'File', 'name', 'col-2' ],
        [ 'Type', 'type', 'col-2' ]
        // [ 'Description', 'description', 'col-4' ]
    ];
    let flash_type = null;
    let flash_value;
    function response(data){
        if(data.error){
            flash_type = 'error';
            flash_value = data.error.join(' ');
        }
        else{
            flash_type = 'success';
            if(data.deleted){
                flash_value = data.deleted;
            }
            else{
                flash_value = "created " + data.name;
            }
            setTimeout( () => dispatch('reload', '') , 1000 );
        }
    }
    let asset_id;
    let asset_index;
    let pp;
    function open(){
        pp = getp(`/assets/${asset_id}`)
    }
    function back(){
        pp = null;
    }
    function reload(e){
        open();
    }
 </script>

<style>
</style>

{#if pp}
    <div class="float-right">
        <button class="{btn}" on:click={back}>Return to file list</button>
    </div>
    {#await pp}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then v}
        <div class="float-right p-2">
            {v.name} {asset_id}
        </div>
    {/await}
{:else}
    <Flash {flash_type} {flash_value} />
    <div class="flex justify-around">
        <div>All Files</div>
            <InputUpload partial="preview_data_set_files" key="data_set_id" value={data_set_id} label=Preview />
            <InputUpload partial="upload_data_set_files" key="data_set_id" value={data_set_id} label=Upload />
    </div>
    <Table bind:selected={asset_id} bind:index={asset_index} {columns} rows={assets} use_filter={true} key_column=id height=400 />
{/if}
