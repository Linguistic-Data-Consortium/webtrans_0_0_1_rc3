<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp"
    import Help from './help.svelte';
    import PageTabs from './page_tabs.svelte';
    import UsersTasks from './users_tasks.svelte';
    import Projects from './projects.svelte';
    import KitTypes from './kit_types.svelte';
    import ClassDefs from './class_defs.svelte';
    import DataSets from './data_sets.svelte';
    import Features from './features.svelte';
    import Services from './services.svelte';
    import Workflows from './workflows.svelte';
    import Groups from './groups.svelte';
    import Invites from './invites.svelte';
    import Scripts from './scripts.svelte';
    import BrowseA from './browse_a.svelte';
    import Browse from './browse.svelte';
    export let admin = false;
    export let portal_manager = false;
    export let project_manager = false;
    let lead_annotator = project_manager;
    let help = false;
    // export let browser;
    let page = 1;
    function pagef(e){ page = e.detail }
    let pages = [
        [ 'Work',        'all',            "your tasks with links to start" ],
        [ 'Projects',    'all',            'projects, tasks, kits' ],
        [ 'Browse',      'all',            'browse uploaded files' ],
        [ 'Kit Types',   'lead_annotator', 'tasks require a kit type' ],
        [ 'Tools',       'lead_annotator', 'kit types require a namespace' ],
        [ 'Data Sets',   'lead_annotator', 'tasks can have a data set' ],
        [ 'Invites',     'lead_annotator', 'invite people to the site' ],
        [ 'Scripts',     'lead_annotator', 'write scripts' ],
        [ 'Features',    'admin',          'features for different objects' ],
        [ 'Services',    'admin',          'services' ],
        [ 'Workflows',   'admin',          'workflows' ],
        [ 'Groups',      'admin',          'groups' ],
        [ 'Permissions', 'all',            'explore roles and permissions' ]
    ];
    // <a class="tabnav-tab" aria-current={page==4} on:click={page4}>Browse</a>
    // <a class="tabnav-tab" aria-current={page==5} on:click={page5}>Upload</a>
    let goto_project;
    function project(e){
        page = 2;
        goto_project = e.detail.project_id;
    }
    let goto_task;
    function task(e){
        goto_task = e.detail.task_id;
        project(e);
    }
    // document.getElementById('work1').hidden = true;
    function helpf(e){
        alert(e.detail);
    }
    
    export function browse(x){
        page = 3;
        // browse_a.step1(x);
    }
    let browse_a;
    let browsex;
    export function uploads(e){
        // page5();
        // browsex.get(e);
    }
    let p = getp(window.location);
    console.log('USERS');
    p.then( (x) => console.log(x) )
    let goto_data_set;
    function reload2(e){
        page = 6;
        goto_data_set = e.detail.id;
    }
</script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>Help Mode On</p>
        <p>more info can be found on each tab</p>
    </div>
</Help>

<div>
    {#if admin}
        <div class="pb-2">
          jump to readonly
          <input class="jtro form-control input-block">
        </div>
    {/if}
</div>

<button class="{btn} bg-blue-200 float-right" on:click={() => help = !help}>Help</button>

<PageTabs {pages} {page} on:page={pagef} {admin} {lead_annotator} {help} on:help={helpf} />

{#if page == 1}
    <UsersTasks {help} {admin} {lead_annotator} {p} on:project={project} on:task={task} />
{:else if page == 2}
    <Projects   {help} {admin} {lead_annotator} {goto_project} {goto_task} on:reload2={reload2} />
{:else if page == 3}
    <Browse
        {help}
        {admin}
        {portal_manager}
        {project_manager}
        {p}
        bind:this={browsex}
    />
{:else if page == 4}
    <KitTypes   {help} {admin} {portal_manager} lead_annotator={project_manager} />
{:else if page == 5}
    <ClassDefs  {help} {admin} {portal_manager} lead_annotator={project_manager} />
{:else if page == 6}
    <DataSets   {help} {admin} {portal_manager} lead_annotator={project_manager} {goto_data_set} />
{:else if page == 7}
    <Invites    {help} {admin} {portal_manager} {project_manager} />
{:else if page == 8}
    <Scripts    {help} {admin} {portal_manager} {project_manager} />
{:else if page == 9}
    <Features   {help} {admin} {project_manager} lead_annotator={project_manager} />
{:else if page == 10}
    <Services   {help} {admin} {project_manager} lead_annotator={project_manager} />
{:else if page == 11}
    <Workflows  {help} {admin} {project_manager} lead_annotator={project_manager} />
{:else if page == 12}
    <Groups     {help} {admin} {project_manager} lead_annotator={project_manager} />
{:else if page == 13}
    <div class="col-2 mx-auto">
        {#if admin}
            <div>You're an Admin.</div>
            <div><button class="{btn}" on:click={ () => { admin = false; portal_manager = true } }>Set yourself to Portal Manager</button></div>
        {:else if portal_manager}
            <div>You're a Portal Manager.</div>
            <div><button class="{btn}" on:click={ () => { portal_manager = false; project_manager = true; lead_annotator = true } }>Set yourself to Project Manager</button></div>
        {:else if project_manager}
            <div>You're a Project Manager.</div>
            <div><button class="{btn}" on:click={ () => { project_manager = false; lead_annotator = false } }>Set yourself to normal User</button></div>
        {:else}
            You don't have any global permissions.
        {/if}
    </div>
{/if}

<!-- {:else if page == 3}
    <Invites {admin} project_manager={lead_annotator} />
{:else if page == 4}
    {#await pp}
        loading...
    {:then v}
        <BrowseA bind:this={browse_a} {browser} sel2=x sel3=x tasks={v} />
    {/await}
{:else if page == 5}
    {#await pp}
        loading...
    {:then v}
        <Upload bind:this={upload} tasks={v} />
    {/await}
{/if} -->
