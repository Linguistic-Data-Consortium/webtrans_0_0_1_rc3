<script>
    import { tick } from 'svelte';
    import Modal from '../modal.svelte'
    import InputText from '../work/input_text.svelte'
    import { create_download_tsv, create_download_url } from '../work/download_helper'
    import { create_transcript } from '../waveform/download_transcript_helper'
    import { getp, postp, deletep, patchp } from "../work/getp";
    import { btn, dbtn } from '../work/buttons'
    import Spinner from '../work/spinner.svelte'
    // export let segs;
    export let task_id;
    let files;
    let text;
    let json;
    let name;
    let include_headers = false;
    let filename;
    let link;
    let url;
    let p = Promise.resolve({});
    function create(){
        p = getp(`/kits/all?task_id=${task_id}`).then( (data) => {
            const t = [];
            const zip = new JSZip();
            const folder = zip.folder('transcripts');
            let text;
            for(let kit of data){
                let text = create_transcript(kit.kit_uid, include_speaker, include_section, include_headers, kit.segments);
                folder.file(`${kit.kit_uid}.tsv`, text);
            }
            zip.generateAsync({type: 'blob'}).then( (blob) => {
                url = URL.createObjectURL(blob);
                tick().then( () => link.href = url );
            })
        });
    }
    let include_speaker = false;
    let include_section = false;
    function send_message(){
        ldc_annotate.add_message('0', 'download', null);
        ldc_annotate.submit_form();
    }
    const modal = {
        title: 'Download Transcript',
        buttons: [
            [ 'Save', btn, cancel ]
        ]
    };
    function cancel(){ }
</script>

<style>
    pre {
        width: 800px;
        overflow: auto;
    }
</style>

<Modal {...modal}>
    <div slot=summary>
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
    </div>
    <div slot=body>
        <div class="overflow-auto">
            <div class="Box-body overflow-auto">
                <div>
                    {#await p}
                        <div class="mx-auto w-8 h-8"><Spinner /></div>
                    {:then v}
                      {JSON.stringify(v)}
                    {/await}
                    <div class="form-group">
                        <div class="form-group-header">Filename (.tsv will be appended)</div>
                        <div class="form-group-body">
                            <input
                                type=text
                                class="focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                                bind:value={filename}
                            />
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="form-group-header">
                            <label>
                                <input
                                    type=checkbox
                                    class="focus:ring-indigo-500 focus:border-indigo-500 h-4 w-4 border-gray-300"
                                    bind:checked={include_headers}
                                />
                                Include Headers
                            </label>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="form-group-header">
                            <label>
                                <input
                                    type=checkbox
                                    class="focus:ring-indigo-500 focus:border-indigo-500 h-4 w-4 border-gray-300"
                                    bind:checked={include_speaker}
                                />
                                Include Speaker
                            </label>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="form-group-header">
                            <label>
                                <input
                                    type=checkbox
                                    class="focus:ring-indigo-500 focus:border-indigo-500 h-4 w-4 border-gray-300"
                                    bind:checked={include_section}
                                />
                                Include Section
                            </label>
                        </div>
                    </div>
                </div>
                <!-- {#if json}
                    <button class="{btn}" on:click={add} data-close-dialog>add</button>
                {:else if text}
                    <button class="{btn}" on:click={download}>download</button>
                {/if} -->
                <div><button class="{btn}" on:click={create}>Create</button> a transcript file, which you can preview below
                {#if url}
                    <!-- svelte-ignore a11y-missing-attribute -->
                    and then <a bind:this={link} download={filename}>Download</a>
                {/if}
                {#if json}
                    {#each json as x}
                        {JSON.stringify(x) + "\n"}
                    {/each}
                {:else if text}
                    <h4>Preview</h4>
                    <pre>{text}</pre>
                {/if}
            </div>
        </div>
    </div>
</Modal>
