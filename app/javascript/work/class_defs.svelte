<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Table from './table.svelte'
    import Modal from './modall.svelte'
    import Flash from './flash.svelte'
    import ClassDef from './class_def.svelte'
    import Spinner from './spinner.svelte'
    export let admin = false;
    export let lead_annotator = false;
    let name;
    let p;
    function get(){ p = getp('/class_defs') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
        // [ 'Task Count', 'task_count', 'col-1' ]
    ];
    const createm = {
        name: 'create_class_def_modal',
        title: 'Create Namespace',
        h: ''
    };
    const deletem = {
        name: 'delete_class_def_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete Namespace',
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
            }
            else{
                flash_value = "created " + data.class_def.name;
            }
            get();
        }
    }
    function create(){
        postp(
            "/class_defs",
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/class_defs/${class_def_id}`
        ).then(response);
    }
    let class_def_id;
    let class_def_index;
    let pp;
    function open(){
        pp = getp(`/class_defs/${class_def_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    // setTimeout(()=>{
    //     // class_def_id = 57;
    //     class_def_id = 33;
    //     open()
    // }, 1000)
    function reload(e){
        open();
    }
</script>

<style>
</style>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" on:click={back}>Return to namespace list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            ClassDef
            <!-- <ClassDef {admin} {lead_annotator} {class_def_id} {...v} /> -->
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            <div>All Namespaces</div>
            {#if class_def_id}
                <div>
                    <button class="{btn}" on:click={open}>Open</button>
                </div>
                {#if admin}
                    <Modal {...deletem}>
                        <div slot=summary>
                            Delete
                        </div>
                        <div slot=body>
                            This will delete the kit type {class_def_index[class_def_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    <div slot=summary>
                        Create Namespace
                    </div>
                    <div slot=body>
                        <form>
                            <label>
                                Name
                                <input type=text bind:value={name}/>
                            </label>
                        </form>
                    </div>
                    <div slot=footer>
                        <button type="button" class="{btn}" data-close-dialog on:click={create}>Save</button>
                    </div>
                </Modal>
            {/if}
        </div>
        <Table bind:selected={class_def_id} bind:index={class_def_index} {columns} rows={v} use_filter={true} key_column=id height=400 />
    {/if}
{/await}
