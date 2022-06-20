<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Modal from '../modal.svelte'
    import Spinner from './spinner.svelte'
    export let help;
    export let admin = false;
    let unused = admin;
    export let tasksp;
    let pp;
    let p;
    let columns = [
        [ 'Source', 'source_id', 'col-1' ],
        [ 'Filename', 'filename', 'col-3' ],
        [ 'Key', 'key', 'col-2' ],
        [ 'User', 'user', 'col-1' ],
        [ 'Task', 'task', 'col-2' ]
    ];
    const h = {
        title: 'Upload File',
        h: ''
    };
    let project_id;
    let task_id = 0;
    let files;
    let upload_e;
    export function get(e){
        upload_e = e;
        p = getp("/browser?blobs=audio");
    }
    get();
    $: pp = getp("/sources/get_upload?task_id=" + task_id);
</script>

<style>
</style>

<!-- <div class=upload4>
  <p>
    After uploading, a code snippet is shown for creating a url
    for that file in Ruby code.  The part that varies is the integer source
    id.  This id can also be found on the Files tab.  In an erb file,
    the ruby code would have to be within &lt;%= %&gt; tags.  In a haml file, the
    ruby code would have to follow = (and appropripate indentation).
  </p>
</div> -->
<div class=upload5>
  <!-- = @du -->
</div>

{#if upload_e}
    <!-- {JSON.stringify(upload_e.detail[0])} -->
{/if}

<Help {help}>
    <div slot=content>
        <p>
            If you're a member of a browesable task, you can upload audio files into that task.
            The table shows the files you've uploaded.
        </p>
    </div>
</Help>

<div>
    <div class="flex justify-around">
        <div>
            Your uploads
        </div>
        <Modal {...h}>
            <div slot=summary>
                Upload file
            </div>
            <div slot=body>
                <!-- <form on:submit|preventDefault={()=>null}> -->
                <div style="width: 600px">
                    {#await tasksp}
                        loading...
                    {:then v}
                        <!-- {JSON.stringify(v[0])} -->
                        {#if v[0].length}
                            <div>Upload into one of these tasks</div>
                            <label for=x>Project/Task</label>
                            <select id=x class="form-select" bind:value={task_id}>
                                <option value={null}></option>
                                {#each v[0] as task}
                                    {#if task.free}
                                        <option value={task.task_id}>
                                            {task.project} / {task.task}
                                        </option>
                                    {/if}
                                {/each}
                            </select>
                            {#if task_id}
                                {#await pp}
                                    <div class="mx-auto w-8 h-8"><Spinner /></div>
                                {:then v}
                                    <div class="m-3">
                                        {@html v.html}
                                    </div>
                                {/await}
                            {/if}
                        {:else}
                            <div>No tasks are available for upload</div>
                        {/if}
                        <!-- <select class="form-select" aria-label="Important decision">
                            <option>Select</option>
                            <option value="option 2">Option 2</option>
                          </select> -->
                    {/await}
                </div>
            </div>
        </Modal>
    </div>
    {#await p}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then rows}
        <Table {columns} {rows} use_filter={true} key_column=source_id height=500 />
    {/await}
</div>
