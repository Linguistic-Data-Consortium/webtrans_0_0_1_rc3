<script>
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep } from './getp'
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Modal from '../modal.svelte'
    import Flash from './flash.svelte'
    import Task from './task.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    import { btn, dbtn } from './buttons'
    export let help;
    export let project_id;
    export let project_admin = false;
    export let tasks;
    export let project_users;
    export let goto_task;
    let name;
    // let p;
    // function get(){ p = getp('/tasks') }
    // get();
    
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Task', 'name', 'col-2' ],
        [ 'Available Kits', 'available_kit_count', 'col-1' ],
        [ 'Source UID', 'source_uid', 'col-1' ]
    ];
    const createm = {
        name: 'create_task_modal',
        title: 'Create Task',
        h: '',
        buttons: [
            [ 'Save', btn, create ]
        ]
    };
    const deletem = {
        name: 'delete_task_modal',
        title: 'Delete Task',
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
            setTimeout( () => dispatch('reload', '') , 1000 );
        }
    }
    function create(){
        postp(
            `/projects/${project_id}/tasks`,
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/projects/${project_id}/tasks/${task_id}`
        ).then(response);
    }
    let task_id;
    let task_index;
    let pp;
    function open(){
        pp = getp(`/projects/${project_id}/tasks/${task_id}`)
    }
    let info = false;
    function openi(){
        info = true;
        open();
    }
    function back(){
        pp = null;
    }
    if(goto_task){
        tick().then(() => {
            // task_id = 1766;
            task_id = goto_task;
            open()
        });
    }
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

<Help {help}>
    <div slot=content>
        <p>Tasks contain Kits</p>
        <p>Select and Open a Task from the table</p>
        {#if project_admin}
            <p>You also have permission to create a new Task</p>
        {/if}
    </div>
</Help>

{#if false}
    loading...
{:else}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" on:click={back}>Return to task list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name} {task_id}
            </div>
            <Task {help} {project_admin} {project_id} {task_id} {...v} {project_users} on:reload={reload} {info} />
            <!-- {task_id} {task_index[task_id].name} -->
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            {#if project_admin}
                <div>All Tasks</div>
            {:else}
                <div>My Tasks</div>
            {/if}
            {#if task_id}
                <div>
                    <button class={btn} on:click={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div class="p-1"><button class="{btn}" on:click={openi}>Open Task Info</button></div>
                        <div class="p-1"><button class="{btn}" on:click={open}>Open Kit List</button></div>
                    </div>
                {/if}
                {#if project_admin}
                    <Modal {...deletem}>
                        <div slot=summary>
                            Delete
                        </div>
                        <div slot=body>
                            This will delete the task {task_index[task_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {/if}
            {#if project_admin}
                <Modal {...createm}>
                    <div slot=summary>
                        Create Task
                    </div>
                    <div slot=body>
                        <form on:submit|preventDefault={()=>null}>
                            <InputText label=Name key=name bind:value={name} />
                       </form>
                    </div>
                </Modal>
            {/if}
        </div>
        <Table bind:selected={task_id} bind:index={task_index} {columns} rows={tasks} use_filter={true} key_column=id height=400 on:selected={selected} />
    {/if}
{/if}
