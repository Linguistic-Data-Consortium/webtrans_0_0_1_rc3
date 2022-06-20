<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep } from './getp'
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Modal from '../modal.svelte'
    import TaskUser from './task_user.svelte'
    import SelectUsers from './select_users.svelte'
    import { btn, dbtn } from './buttons'
    export let project_id;
    export let task_id;
    export let task_admin = false;
    export let task_users;
    export let project_users;
    export const help = false;
    let unused = project_id;
    let columns = [
        [ 'User ID', 'user_id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ],
        [ 'State', 'state', 'col-1' ],
        [ 'Admin', 'admin', 'col-1 ']
    ];
    const deletem = {
        name: 'delete_task_user_modal',
        title: 'Remove Member',
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
                flash_value = data.ok;
            }
            setTimeout( () => dispatch('reload', '') , 1000 );
        }
    }
    function create(){
        postp(
            `/task_users`,
            { task_id: task_id, user_id: user_id }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/task_users/${task_user_id}`
        ).then(response);
    }
    let task_user_id;
    let task_user_index;
    let user_id;
    function auto2(x){
        user_id = x.user_id;
        create();
    }
    let is_admin;
    $: {
        if(task_user_id){
            is_admin = task_user_index[task_user_id].admin;
        }
    }
</script>

<style>
</style>

{#if flash_type}
    <div class="text-center flash flash-{flash_type} mb-3">
        {flash_value}
        <button type=button class="close flash-close js-flash-close">
            <i class="fa fa-times"></i>
        </button>
    </div>
{/if}
<div class="flex justify-around">
    <div>Members</div>
    {#if task_user_id}
        {#if task_admin}
            <Modal {...deletem}>
                <div slot=summary>
                    Remove User
                </div>
                <div slot=body>
                    This will remove {task_user_index[task_user_id].name}, are you sure you want to do this?
                </div>
            </Modal>
        {/if}
    {/if}
    {#if task_admin}
        <SelectUsers urlf={project_users} {create} {auto2} />
    {/if}
</div>
<div class="flex">
    <div class="w-1/2 col-{task_user_id ? '6' : '12'}">
        <Table bind:selected={task_user_id} bind:index={task_user_index} {columns} rows={task_users} use_filter={true} key_column=id height=400 />
    </div>
    <div class="float-left col-6 p-6">
        {#if task_user_id && task_admin}
            {#each task_users as x}
                {#if x.id == task_user_id}
                    <TaskUser id={x.id} is_admin={x.admin} state={x.state} on:reload />
                {/if}
            {/each}
        {/if}
    </div>
</div>
