<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Modal from './modall.svelte'
    import GroupUser from './group_user.svelte'
    import Spinner from './spinner.svelte'
    // export let project_id;
    export let group_id;
    export let group_users;
    export const help = false;
    let columns = [
        [ 'User ID', 'user_id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
    ];
    const createm = {
        name: 'create_group_user_modal',
        title: 'Add Member',
        h: ''
    };
    const deletem = {
        name: 'delete_group_user_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Remove Member',
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
                flash_value = data.ok;
            }
            setTimeout( () => dispatch('reload', '') , 1000 );
        }
    }
    function create(x){
        name = x.name;
        user_id = x.id;
        postp(
            `/group_users`,
            { group_id: group_id, user_id: user_id }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/group_users/${group_user_id}`
        ).then(response);
    }
    let group_user_id;
    let group_user_index;
    let name;
    let user_id = null;
    let pp;
    // $: pp = getp(`/projects/${project_id}/users_not_in_project?term=${name}`)
    function back(){
        pp = null;
    }
    function auto2(x){
    }
    const group_admin = true;
    let timeout;
    function auto(x){
        if(!x || x.length < 3) return;
        if(timeout) clearTimeout(timeout);
        timeout = setTimeout(() => {
            pp = getp(`/groups/${group_id}/users_not_in?term=${name}`);
        }, 500);
    }
    $: auto(name);
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
    {#if group_user_id}
        {#if group_admin}
            <Modal {...deletem}>
                <div slot=summary>
                    Remove User
                </div>
                <div slot=body>
                    This will remove {group_user_index[group_user_id].name}, are you sure you want to do this?
                </div>
            </Modal>
        {/if}
    {/if}
</div>
<div class="flex justify-around p-6">
    <div class="float-left col-6">
        <Table bind:selected={group_user_id} bind:index={group_user_index} {columns} rows={group_users} use_filter={true} key_column=id height=400 />
    </div>
    <div class="float-left col-6">
        <div>
            Add User
        </div>
        <div>
            <form>
                <label>
                    Name
                    <input type=text bind:value={name}/>
                    {#if pp}
                        {#await pp}
                            <div class="mx-auto w-8 h-8"><Spinner /></div>
                        {:then users}
                            {#each users as x}
                                {#if x.name.includes(name)}
                                    <div on:click={ () => create(x) }>{x.name}</div>
                                {/if}
                            {/each}
                        {/await}
                    {/if}
                </label>
            </form>
        </div>  
    </div>
</div>
