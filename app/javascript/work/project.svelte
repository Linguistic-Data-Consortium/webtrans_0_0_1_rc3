<script>
    import Help from './help.svelte'
    import PageTabs from './page_tabs.svelte'
    import Table from './table.svelte'
    import Tasks from './tasks.svelte'
    import Members from './project_users.svelte'
    import InputText from './input_text.svelte'
    export let help;
    export let admin = false;
    export let lead_annotator = false;
    export let project_id;
    export let goto_task;

    export let id
    export let name;
    export let project_owner_bool;
    export let project_admin_bool;
    export let tasks;
    export let project_users;
    export let info = null;
    let unused = admin && lead_annotator && info;
    let page = 2;
    function pagef(e){ page = e.detail }
    let pages = [
        [ 'Project Info', 'all', 'project attributes' ],
        [ 'Tasks', 'all', 'tasks, kits' ],
        [ 'Project Members', 'admin', 'members of this project' ]
    ];
    let url = `/projects/${project_id}`;
</script>

<style>
</style>

<PageTabs {help} {pages} {page} on:page={pagef} admin={project_admin_bool} />

{#if page == 1}
    {#if project_owner_bool}
        <div class="col-3 mx-auto">
            <div>ID: {id}</div>
            <div>
                <InputText {url} label=Name key=name value={name} />
            </div>
        </div>
    {:else}
        <div class="col-3 mx-auto">
            <div>ID: {id}</div>
            <div>Name: {name}</div>
        </div>
    {/if}
{:else if page == 2}
    <Tasks
        {help}
        {project_id}
        project_admin={project_admin_bool}
        {tasks}
        {project_users}
        on:reload
        {goto_task}
    />
{:else if page == 3}
    <Members
        {project_id}
        project_owner={project_owner_bool}
        project_admin={project_admin_bool}
        {project_users}
        on:reload
    />
{/if}
