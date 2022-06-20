<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Modal from '../modal.svelte'
    import Flash from './flash.svelte'
    import DataSet from './data_set.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    export let help;
    export let admin = false;
    export let lead_annotator = false;
    let name;
    let p;
    function get(){ p = getp('/data_sets') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Data Set', 'name', 'col-1' ],
        [ 'Spec', 'spec', 'col-1' ],
        [ 'Description', 'description', 'col-8' ]
    ];
    const createm = {
        name: 'create_data_set_modal',
        title: 'Create data_set',
        h: '',
        buttons: [
            [ 'Create', cbtn, create ]
        ]
    };
    const deletem = {
        name: 'delete_data_set_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete data_set',
        h: ''
    };
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
                data_set_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
            get();
        }
    }
    function create(){
        postp(
            "/data_sets",
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/data_sets/${data_set_id}`
        ).then(response);
    }
    let data_set_id;
    let data_set_index;
    let pp;
    function open(){
        pp = getp(`/data_sets/${data_set_id}`)
    }
    function back(){
        pp = null;
        get();
    }
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
        <p>data_sets</p>
    </div>
</Help>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" on:click={back}>Return to Feature list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <DataSet {help} {admin} {lead_annotator} {data_set_id} {...v} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            <div>All data_sets</div>
            {#if data_set_id && data_set_index}
                <div>
                    <button class="{btn}" on:click={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div><button class="{btn}" on:click={open}>Open</button></div>
                    </div>
                {/if}
                {#if admin}
                    <Modal {...deletem}>
                        <div slot=summary>
                            Delete
                        </div>
                        <div slot=body>
                            This will delete the data_set {data_set_index[data_set_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {:else}
                Select a data_set in the table for more options.
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    <div slot=summary>
                        Create data_set
                    </div>
                    <div slot=body>
                         <form on:submit|preventDefault={()=>null}>
                             <InputText label=Name key=name bind:value={name} />
                        </form>
                    </div>
                    <div slot=footer>
                        <button type="button" class="{btn}"   data-close-dialog on:click={create}>Save</button>
                    </div>
                </Modal>
            {/if}
        </div>
        <Table bind:selected={data_set_id} bind:index={data_set_index} {columns} rows={v} use_filter={true} key_column=id height=400 on:selected={selected}/>
    {/if}
{/await}
