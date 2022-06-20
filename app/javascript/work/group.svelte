<script>
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import PageTabs from './page_tabs.svelte'
    import Members from './group_users.svelte'
    import InputText from './input_text.svelte'
    import InputSelect from './input_select.svelte'
    // export let help;
    export let admin = false;
    // export let lead_annotator = false;

    export let id;
    export let name;
    export let group_users;


    let url = `/groups/${id}`;

    let page = 2;
    function pagef(e){ page = e.detail }
    let pages = [
        [ 'Group Info', 'all', 'task attributes' ],
        [ 'Group Members' , 'admin', 'members of this task' ]
    ];
</script>

<style>
</style>

<PageTabs {pages} {page} on:page={pagef} admin={admin} />

{#if page == 1}
    <div class="col-3 mx-auto">
        <div>ID: {id}</div>
        <form on:submit|preventDefault={()=>null}>
            <InputText {url} label=Name key=name value={name} />
        </form>
    </div>
{:else if page == 2}
    <Members
        group_id={id}
        {group_users}
        on:reload
    />
{/if}
