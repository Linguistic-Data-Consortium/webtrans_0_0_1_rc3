<script>
    import { marked } from 'marked';
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import PageTabs from './page_tabs.svelte'
    import Uploads from './uploads.svelte';
    import UploadsTasks from './uploads_tasks.svelte';
    import UploadsKits from './uploads_kits.svelte';
    import Buckets from './buckets.svelte'
    export let help;
    export let admin;
    export let portal_manager;
    export let project_manager;
    // export let project_id;
    // export let project_admin = false;
    // export let project_users;
    // export let goto_task;
    let name;
    export let p;
    let page = 1;
    function pagef(e){ page = e.detail }
    let pages = [
        [ 'Your Uploads',  'all',    'files you uploaded' ],
        [ 'All Uploads',   'all',    'all uploaded files' ],
        [ 'Transcripts',   'all',    'kits created from uploads' ],
        [ 'Buckets',       'admin',  'available buckets' ],
    ];
    let columns = [
        [ 'Task', 'task', 'col-2' ],
        // [ 'Source', 'source_id', 'col-1' ],
        [ 'Type', 'type', 'col-1' ],
        [ 'Filename', 'filename', 'col-3' ],
        // [ 'Key', 'key', 'col-2' ],
        [ 'Last Edited by', 'kit_user', 'col-1' ],
        [ 'Uploaded By', 'user', 'col-1' ],
    ];
    let object_id;
    let object_index;
    function create(){
    // $(that.sel2).on 'click', '.new, .news3', ->
        // if $(this).hasClass('news3')
        //     copen = 's3'
        //     source = $(this).data().key
        // else
        //     copen = 'open'
        //     source = $(this).attr('class').split(' ')[1]
        let copen = 'open';
        let path = `/kits_new?${copen}=${object_index[object_id].source_id}&task_id=${object_index[object_id].task_id}&filename=${object_index[object_id].filename}`
        let pp = getp(path);
        console.log(path);
        pp.then( () => window.location = work_paths[object_index[object_id].task_id] ); 
    }
    function goto_open(){
        console.log(open_tasks);
        let id = open_tasks[object_index[object_id].task_id];
        // let kit = kit_index[kit_id];
        // let task_id = kit.task_id;
        // open_kit_uid = open_tasks[task_id];
        // if(open_kit_uid == kit.uid){
        //     open_kit_uid = null;
        // }
        // if(!open_kit_uid){
            let pp = getp("/kits_new?goto=" + object_index[object_id].id);
            pp.then( () => window.location = work_paths[object_index[object_id].task_id] );
        // }
    }
    function goto_closed(){
        console.log(open_tasks);
        let id = open_tasks[object_index[object_id].task_id];
        // let kit = kit_index[kit_id];
        // let task_id = kit.task_id;
        // open_kit_uid = open_tasks[task_id];
        // if(open_kit_uid == kit.uid){
        //     open_kit_uid = null;
        // }
        // if(!open_kit_uid){
            let pp = getp("/kits_new?goto=" + object_index[object_id].id);
            pp.then( () => window.location = work_paths[object_index[object_id].task_id] );
        // }
    }
    let browse_tasks = [];
    let pp;
    let work_paths = {};
    let open_tasks = {};
    let open_kit_uid;
    let selected_task_id;
    $: {
        if(object_id){
            selected_task_id = object_index[object_id].task_id;
        }
    }
    p.then( (x) => {
        for(let y of x[0]){
            if(y.free){
                browse_tasks.push(getp("/browser?blobs=audio&task_id=" + y.task_id));
                browse_tasks.push(getp("/tasks/" + y.task_id + "?existing=true"));
                work_paths[y.task_id] = y.work_path;
                if(y.state == 'has_kit'){
                    open_tasks[y.task_id] = y.kit_uid;
                }
                else{
                    open_tasks[y.task_id] = false;
                }
            }
        }
        pp = Promise.all(browse_tasks).then( (a) => {
            let b = [];
            for(let x of a){
                for(let y of x){
                    if(y.source_id){
                        y.type = 'file';
                        y.uid = y.key;
                    }
                    else{
                        y.type = 'kit';
                    }
                }
                b = b.concat(x);
            }
            return b;
        });
    });
    let allow_create;
    let allow_return;
    let allow_goto;
    let open_kit;
    $: {
        if(object_id){
            allow_create = object_index[object_id].type == 'file';
            open_kit = open_tasks[object_index[object_id].task_id];
            allow_return = object_index[object_id].uid == open_kit
            allow_goto =  !open_kit && object_index[object_id].type == 'kit';
        }
    }
    let uploads;
    export function get(e){
        uploads.get(e);
    }
 </script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>
            The Browse feature allows you to upload audio files and collaborate on transcripts.
            Uploaded audio files, as well as their transcripts, can be shared among the group.
        </p>
        <p>
            {@html marked.parse("You can upload under **Your Uploads**, create new transcripts under **All Uploads**, and access transcripts under **Transcripts**")}
        </p>
    </div>
</Help>

<PageTabs {pages} {page} on:page={pagef} {admin} lead_annotator={project_manager} {help} />

{#if page == 1}
    <Uploads    {help} {admin}  tasksp={p} bind:this={uploads} />
{:else if page == 2}
        <UploadsTasks
            {help}
            {admin}
            {p}
        />
{:else if page == 3}
        <UploadsKits
            {help}
            {admin}
            {p}
        />
{:else if page == 4}
    <Buckets
        {help}
        {admin}
        {portal_manager}
        {project_manager}
        p_for_bucket={p}
    />
{/if}
