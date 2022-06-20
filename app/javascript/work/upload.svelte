<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Table from './table.svelte'
    import Modal from './modall.svelte';
    import Spinner from './spinner.svelte'
    export let tasks;
    let pp;
    let p;
    let columns = [
        [ 'Source', 'source_id', 'col-1' ],
        [ 'Filename', 'filename', 'col-3' ],
        [ 'Key', 'key', 'col-1' ]
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

<!-- {#if upload_e}
    {JSON.stringify(upload_e.detail[0])}
{/if}
{JSON.stringify(tasks)} -->
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
                    {#if tasks.length}
                        <div>Upload into one of these tasks</div>
                        <label>Project/Task</label>
                        <select class="form-select" bind:value={task_id}>
                            <option value={null}></option>
                            {#each tasks as task}
                                <option value={task.task_id}>
                                    {task.project.replace(/<.+?>/g,'')} / {task.task.replace(/<.+?>/g,'')}
                                </option>
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
                </div>
            </div>
            <div slot=footer>
                <!-- <div class="form-actions">
                    <button type="button" class="{btn}"   data-close-dialog on:click={upload}>Upload</button>
                </div> -->
            </div>
        </Modal>
    </div>
    {#await p}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then rows}
        <Table {columns} {rows} use_filter={true} key_column=source_id height=500 />
    {/await}
</div>
