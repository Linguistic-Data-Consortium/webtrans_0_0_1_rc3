<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep } from './getp'
    import Table from './table.svelte'
    import Modal from '../modal.svelte'
    import ProjectUser from './project_user.svelte'
    import Spinner from './spinner.svelte'
    import SelectUsers from './select_users.svelte'
    import { btn, dbtn } from './buttons'
    export let project_id;
    export let project_owner = false;
    export let project_admin = false;
    export let project_users;
    let columns = [
        [ 'User ID', 'user_id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
    ];
    const deletem = {
        name: 'delete_project_user_modal',
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
            `/project_users`,
            { project_id: project_id, user_id: user_id }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/project_users/${project_user_id}`
        ).then(response);
    }
    let project_user_id;
    let project_user_index;
    let name;
    let user_id;
    let pp;
    // $: pp = getp(`/projects/${project_id}/users_not_in_project?term=${name}`)
    function back(){
        pp = null;
    }
    const urlf = (name) => `/projects/${project_id}/users_not_in_project?term=${name}`;
    // $: auto(name);
    function auto2(x){
        user_id = x.id;
        create();
    }
    let is_owner;
    let is_admin;
    $: {
        if(project_user_id){
            is_owner = project_user_index[project_user_id].owner;
            is_admin = project_user_index[project_user_id].admin;
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
    {#if project_user_id}
        {#if project_admin}
            <Modal {...deletem}>
                <div slot=summary>
                    Remove User
                </div>
                <div slot=body>
                    This will remove {project_user_index[project_user_id].name}, are you sure you want to do this?
                </div>
            </Modal>
        {/if}
    {/if}
    {#if project_admin}
        <SelectUsers {urlf} {create} {auto2} />
    {/if}
</div>
<div class="flex justify-aroundx p-6">
    <div class="w-1/2 col-{project_user_id ? '6' : '12'}">
        <Table bind:selected={project_user_id} bind:index={project_user_index} {columns} rows={project_users} use_filter={true} key_column=id height=400 />
    </div>
    <div class="float-left col-6 p-6">
        {#if project_user_id && project_owner}
            {#each project_users as x}
                {#if x.id == project_user_id}
                    <ProjectUser id={x.id} is_owner={x.owner} is_admin={x.admin} />
                {/if}
            {/each}
        {/if}
    </div>
</div>
