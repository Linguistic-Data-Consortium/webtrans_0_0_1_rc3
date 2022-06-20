<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Modal from './modall.svelte'
    import Flash from './flash.svelte'
    import Workflow from './workflow.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    export let help;
    export let admin = false;
    export let lead_annotator = false;
    let category;
    let name;
    let p;
    function get(){ p = getp('/workflows') }
    get();
    let columns = [
        [ 'Name', 'name', 'col-1' ],
        [ 'Description', 'description', 'col-1' ],
        [ 'Type', 'type', 'col-1' ],
    ];
    const createm = {
        name: 'create_workflow_modal',
        title: 'Create workflow',
        h: ''
    };
    const deletem = {
        name: 'delete_workflow_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete workflow',
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
                workflow_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
            get();
        }
    }
    function create(){
        postp(
            "/workflows",
            { category: category, name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/workflows/${workflow_id}`
        ).then(response);
    }
    let workflow_id;
    let workflow_index;
    let pp;
    function open(){
        pp = getp(`/workflows/${workflow_id}`)
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
        <p>workflows</p>
    </div>
</Help>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" on:click={back}>Return to Workflow list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Workflow {help} {admin} {lead_annotator} {workflow_id} {...v} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            <div>All workflows</div>
            {#if workflow_id && workflow_index}
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
                            This will delete the workflow {workflow_index[workflow_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {:else}
                Select a workflow in the table for more options.
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    <div slot=summary>
                        Create workflow
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
        <Table bind:selected={workflow_id} bind:index={workflow_index} {columns} rows={v} use_filter={true} key_column=id height=400 on:selected={selected} />
    {/if}
{/await}
