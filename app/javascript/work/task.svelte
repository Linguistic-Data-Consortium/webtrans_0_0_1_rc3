<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import Help from './help.svelte'
    import PageTabs from './page_tabs.svelte'
    import Table from './table.svelte'
    import Members from './task_users.svelte'
    import Kits from './kits.svelte'
    import Duals from './duals.svelte'
    import InputText from './input_text.svelte'
    import InputSelect from './input_select.svelte'
    import InputCheckbox from './input_checkbox.svelte'
    export let help;
    export let project_admin = false;
    export const lead_annotator = false;
    export let project_id;
    export let task_id;
    export let project_users;
    export let info = null;

    export let id;
    export let name;
    export let status;
    export let workflow_id;
    export let workflows;
    export let kit_type_id;
    export let kit_types;
    export let data_set_id;
    export let data_sets;
    export let task_admin_bool;
    export let task_users;
    export let class_def;
    export let tables;
    export let ann;
    export let ann2;
    export let diff;
    export let source_uid;
    export let meta;
    export let features;
    export let tasks;
    export let bucket;
    export let bucket_size;
    let unused = source_uid;

    let page = 2;
    if(info){
        page = 1;
    }
    function pagef(e){ page = e.detail }
    let pages = [
        [ 'Task Info', 'all', 'task attributes' ],
        [ 'Kits', 'all', 'kits in this task' ],
        [ 'Duals', 'all', 'duals in this task' ],
        [ 'Task Members', 'admin', 'members of this task' ],
        [ 'Output Tables', 'admin', 'status of annotation output tables' ]
    ];
    let url = `/projects/${project_id}/tasks/${task_id}`;
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'User', 'user_id', 'col-1' ],
        [ 'Admin', 'admin', 'col-1' ]
    ]
    let statuses = [ 'active', 'inactive' ];
    let workflow;
    let workflows_menu = [];
    for(let x of workflows){
        if(
            (
                x.name != 'Bucket' &&
                x.name != 'BucketUser' &&
                x.name != 'SecondPass'
            )
            ||
            x.id == workflow_id
        ){
            workflows_menu.push(x);
        }
        if(x.id == workflow_id){
            workflow = x;
            // break;
        }
    }
    let kit_type;
    for(let x of kit_types){
        if(x.id == kit_type_id){
            kit_type = x;
            break;
        }
    }
    let data_set;
    data_sets = [ { id: null, name: 'none'} ].concat(data_sets);
    for(let x of data_sets){
        if(x.id == data_set_id){
            data_set = x;
            break;
        }
    }
    let menu_task;
    let menu_tasks = [ { id: 0, name: 'none'} ].concat(tasks);
    if(meta['1p_task_id']){
        for(let x of tasks){
            if(x.id == Number(meta['1p_task_id'])){
                menu_task = x;
                break;
            }
        }
    }
    else{
        menu_task = menu_tasks[0];
    }
    let constraintb = {};
    for(let x of features){
        if(x.name == x.value){
            constraintb[x.name] = meta[x.name] == x.name;
        }
        else{
            constraintb[x.name] = meta[x.name];
        }
    }
</script>

<style>
</style>

<PageTabs {help} {pages} {page} on:page={pagef} admin={task_admin_bool} />

{#if page == 1}
    {#if project_admin}
        <div class="w-96 mx-auto">
            <div>ID: {id}</div>
            <form on:submit|preventDefault={()=>null}>
                <InputText   {url} label=Name key=name bind:value={name} />
                <InputSelect {url} label=Status key=status value={status} values={statuses} />
                <InputSelect {url} label=Workflow key="workflow_id" value={workflow} values={workflows_menu} att=name />
                <InputSelect {url} label=KitType key="kit_type_id" value={kit_type} values={kit_types} att=name />
                <InputSelect {url} label=DataSet key="data_set_id" value={data_set} values={data_sets} att=name />
                {#each features as x}
                    {#if x.name == x.value}
                        <InputCheckbox {url} label={x.label} key={x.name} value={constraintb[x.name]} meta={'meta'} />
                    {:else if x.name == '1p_task_id'}
                        <InputSelect {url} label={x.label} key={x.name} value={menu_task} values={menu_tasks} att=name meta={'meta'} />
                    {:else if x.name == 'docid' || x.name == 'notes' || x.name == 'dual_percentage' || x.name == 'dual_minimum_duration'}
                        <InputText {url} label={x.label} key={x.name} value={constraintb[x.name]} meta={'meta'} />
                    {:else}
                        <InputText {url} label={x.label} key={x.name} value={constraintb[x.name]} />
                    {/if}
                {/each}
            </form>
            <div>
                {#if bucket}
                    Bucket {bucket} has {bucket_size} files
                {:else}
                    no bucket for this task
                {/if}
            </div>
        </div>
    {:else}
        <div class="col-3 mx-auto">
            <div>ID: {id}</div>
            <div>Name: {name}</div>
        </div>
    {/if}
{:else if page == 2}
    <Kits
        {help}
        {project_id}
        {task_id}
        task_admin={task_admin_bool}
        {task_users}
    />
{:else if page == 3}
    <Duals
        {help}
        {project_id}
        {task_id}
        task_admin={task_admin_bool}
        {task_users}
        {meta}
    />
{:else if page == 4}
    <Members
        {project_id}
        {task_id}
        task_admin={task_admin_bool}
        {task_users}
        {project_users}
        on:reload
    />
{:else if page == 5}
    <div>
        Annotation Output Tables
    </div>
    <div>
        (not required for annotation)
    </div>
    {#if class_def}
        <div>
            <div>
                {#if tables}
                    tables exist
                {:else}
                    tables don't exist
                {/if}
            </div>
            <div>
                {#if ann}
                    {ann} last annotation
                {/if}
                {#if ann2}
                    <div>
                        {ann2} last in tables
                    </div>
                    <div>
                        behind by {diff} hours
                    </div>
                {:else}
                    <div>
                        nothing in tables
                    </div>
                {/if}
            </div>
        </div>
    {/if}
{/if}
