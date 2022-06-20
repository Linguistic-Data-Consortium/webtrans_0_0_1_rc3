<script>
    import Table from './table.svelte'
    import Modal from './modall.svelte'
    import InputSelect from './input_select.svelte'
    export let task_admin = false;
    // export let lead_annotator = false;
    // export let project_id;
    // export let task_id;
    export let id;
    export let uid;
    export let name;
    export let user_id;
    export let task_users;

    let url = `/kits/${id}/update`;
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'User', 'user_id', 'col-1' ],
        [ 'Admin', 'admin', 'col-1' ]
    ]
    let menu_user;
    let menu_users = [ { user_id: 0, name: 'none'} ].concat(task_users);
    if(user_id){
        for(let x of task_users){
            if(x.user_id == user_id){
                menu_user = x;
                break;
            }
        }
    }
    else{
        menu_user = menu_users[0];
    }
</script>

<style>
</style>

{#if task_admin}
    <div class="col-3 mx-auto">
        <div>ID: {id}</div>
        <div>UID: {uid}</div>
        <form on:submit|preventDefault={()=>null}>
            <InputSelect
                {url}
                label=User
                key="user_id"
                value={menu_user}
                values={menu_users}
                att=name
                idk="user_id"
            />
        </form>
    </div>
{:else}
    <div class="col-3 mx-auto">
        <div>ID: {id}</div>
        <div>Name: {name}</div>
    </div>
{/if}
