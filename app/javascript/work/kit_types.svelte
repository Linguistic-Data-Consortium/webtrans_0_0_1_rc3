<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Table from './table.svelte'
    import Modal from '../modal.svelte'
    import Flash from './flash.svelte'
    import KitType from './kit_type.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    export let admin = false;
    export let lead_annotator = false;
    export let help;
    export let portal_manager;
    let unused = help && portal_manager;
    let name;
    let p;
    function get(){ p = getp('/kit_types') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
        // [ 'Task Count', 'task_count', 'col-1' ]
    ];
    const createm = {
        name: 'create_kit_type_modal',
        title: 'Create Kit Type',
        h: '',
        buttons: [
            [ 'Save', btn, create ]
        ]
    };
    const deletem = {
        name: 'delete_kit_type_modal',
        title: 'Delete Kit Type',
        h: '',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ]
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
            }
            else{
                flash_value = "created " + data.name;
            }
            get();
        }
    }
    function create(){
        postp(
            "/kit_types",
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/kit_types/${kit_type_id}`
        ).then(response);
    }
    let kit_type_id;
    let kit_type_index;
    let pp;
    function open(){
        pp = getp(`/kit_types/${kit_type_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    // setTimeout(()=>{
    //     // kit_type_id = 57;
    //     kit_type_id = 33;
    //     open()
    // }, 1000)
    function reload(e){
        open();
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

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" on:click={back}>Return to kit type list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <KitType {admin} {lead_annotator} {kit_type_id} {...v} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            <div>All Kit Types</div>
            {#if kit_type_id}
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
                            This will delete the kit type {kit_type_index[kit_type_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    <div slot=summary>
                        Create Kit Type
                    </div>
                    <div slot=body>
                        <form on:submit|preventDefault={()=>null}>
                            <InputText label=Name key=name bind:value={name} />
                       </form>
                    </div>
                </Modal>
            {/if}
        </div>
        <Table bind:selected={kit_type_id} bind:index={kit_type_index} {columns} rows={v} use_filter={true} key_column=id height=400 on:selected={selected} />
    {/if}
{/await}
