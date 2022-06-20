<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Table from './table.svelte'
    import Modal from './modall.svelte'
    import Flash from './flash.svelte'
    import KitBatch from './kit_batch.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    export let admin = false;
    export let lead_annotator = false;
    export let portal_manager = false;
    export let project_manager = true; //false;
    let name;
    let p;
    function get(){ p = getp('/kit_batches') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
        // [ 'Task Count', 'task_count', 'col-1' ]
    ];
    const createm = {
        name: 'create_kit_batch_modal',
        title: 'Create Kit Batch',
        h: ''
    };
    const deletem = {
        name: 'delete_kit_batch_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete Kit Batch',
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
                flash_value = "created " + data.name;
            }
            get();
        }
    }
    function create(){
        postp(
            "/kit_batches",
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/kit_batches/${kit_batch_id}`
        ).then(response);
    }
    let kit_batch_id;
    let kit_batch_index;
    let pp;
    function open(){
        pp = getp(`/kit_batches/${kit_batch_id}`)
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
    let role;
    let project_id;
    let task_id;
</script>

<style>
</style>

{#await p}
    loading...
{:then v}
    {JSON.stringify(v)}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" on:click={back}>Return to kit batch list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <KitBatch {admin} {lead_annotator} {kit_batch_id} {...v} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            <div>All Kit Batches</div>
            {#if kit_batch_id}
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
                            This will delete the kit batch {kit_batch_index[kit_batch_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    <div slot=summary>
                        Create Kit Batch
                    </div>
                    <div slot=body>
                        <form on:submit|preventDefault={()=>null}>
                            <InputText label=Name key=name bind:value={name} />
                           {#if project_manager}
                               <div class="pt-2">
                                   <div>If you want to automatically add the invitee to</div>
                                   <div>a project and/or task, select those here.</div>
                               </div>
                               {#await p}
                                   loading...
                               {:then v}
                                   <div>
                                       <label for=x>Project</label>
                                       <select id=x class="form-select" bind:value={project_id}>
                                           <option value={null}></option>
                                           {#each v.projects as project}
                                               <option value={project.id}>
                                                   {project.name}
                                               </option>
                                           {/each}
                                       </select>
                                   </div>
                                   <div>
                                       {#if project_id}
                                           <label for=y>Task</label>
                                           <select id=y class="form-select" bind:value={task_id}>
                                               <option value={null}></option>
                                               {#each v.tasks_index[project_id] as task}
                                                   <option value={task.id}>
                                                       {task.name}
                                                   </option>
                                               {/each}
                                           </select>
                                       {/if}
                                   </div>
                               {/await}
                           {/if}
                           <!-- <select class="form-select" aria-label="Important decision">
                               <option>Select</option>
                               <option value="option 2">Option 2</option>
                             </select> -->
                       </form>
                    </div>
                    <div slot=footer>
                        <button type="button" class="{btn}"   data-close-dialog on:click={create}>Save</button>
                    </div>
                </Modal>
            {/if}
        </div>
        <Table bind:selected={kit_batch_id} bind:index={kit_batch_index} {columns} rows={v.kit_batches} use_filter={true} key_column=id height=400 on:selected={selected} />
    {/if}
{/await}
