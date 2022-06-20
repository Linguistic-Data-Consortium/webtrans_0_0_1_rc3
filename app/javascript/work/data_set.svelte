<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { DirectUpload } from "activestorage"
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import PageTabs from './page_tabs.svelte'
    import Files from './data_set_files.svelte';
    import InputText from './input_text.svelte'
    import InputSelect from './input_select.svelte'
    import InputUpload from './input_upload.svelte'
    import InputOnce from './input_once.svelte'
    import Spinner from './spinner.svelte'
    export let help;
    export const admin = false;
    export const lead_annotator = false;

    export let data_set_id;
    export let name;
    export let description;
    export let manifest_url;
    // export let spec;
    export let files;

    let page = 2;
    function pagef(e){ page = e.detail }
    let pages = [
        [ 'Data Set Info', 'admin', 'data set attributes' ],
        [ 'Files',         'admin', 'media files uploaded' ]
    ];

    let url = `/data_sets/${data_set_id}`;
    let menu_file = {id: 0, name: ''};
    const menu_files = [ menu_file ];
    for(let x of files){
        if(x.type == 'text/plain'){
            menu_files.push(x);
        }
    }
    let p;
    $: p = menu_file.name.length ? getp(`${url}?file_id=${menu_file.id}`) : Promise.resolve({file:''});
    function create(){
        p = p.then( (data) => {
            let o = { list: [] }
            const lines = data.file.split(/\r?\n/);
            const header = lines[0].split(/\t/);
            for(let i = 1; i < lines.length; i++){
                let line = lines[i];
                if(line.length){
                    line = line.split(/\t/);
                    let oo = {};
                    o.list.push(oo);
                    for(let ii = 0; ii < header.length; ii++){
                        oo[header[ii]] = line[ii];
                    }
                }
            }
            return o;
        } );
        p.then( (data) => {
            const blob = new Blob([JSON.stringify(data, null, 2)], {type : 'application/json'});
            const file = new File([blob], menu_file.name.replace(/txt$/, 'json'));
            const input = document.querySelector('input[type=file]');
            const url = input.dataset.directUploadUrl;
            const upload = new DirectUpload(file, url);
            console.log(upload)
            upload.create((error, blob) => {
                if (error) {
                  // Handle the error
                  console.log(error);
                } else {
                    console.log(blob);
                    signed_id = blob.signed_id;
                }
              })
        } );
    }
    let pp;
    $: pp = manifest_url ? getp(manifest_url) : Promise.resolve({list: []});
    let signed_id;
</script>

<style>
    pre {
        width: 200px;
        height: 100px;
        overflow: auto;
    }
</style>

<PageTabs {help} {pages} {page} on:page={pagef} admin={true} />

{#if page == 1}
    <div>ID: {data_set_id}</div>
    <div class="col-6 float-left">
        <form on:submit|preventDefault={()=>null}>
            <InputText {url} label=Name key=name value={name} />
            <InputText {url} label=Description key=description value={description} textarea={true} />
        </form>
    </div>
    <div class="col-6 float-left">
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <pre>
                {#each v.list as x}
                    <div>{JSON.stringify(x)}</div>
                {/each}
            </pre>
        {/await}

        <InputUpload partial="upload_data_set_manifest" key="data_set_id" value={data_set_id} />
        <InputSelect label=Manifest bind:value={menu_file} values={menu_files} att=name />
        {#await p}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div>Preview</div>
            <div>
                <button class="{btn}" on:click={create}>Create Manifest</button>
            </div>
            {#if signed_id}
                <InputOnce
                    {url}
                    label=Attach
                    key=manifest
                    value={signed_id}
                    wrap="data_set"
                />
            {/if}
            <pre>
                {#if v.file}
                    {v.file}
                {:else if v.list}
                    {#each v.list as x}
                        <div>{JSON.stringify(x)}</div>
                    {/each}
                {/if}
            </pre>
        {/await}
    </div>
{:else if page == 2}
    <Files
        {help}
        {data_set_id}
        {lead_annotator}
        assets={files}
    />
{/if}
