<script>
    import Modal from '../modal.svelte'
    import CreateTranscript from '../waveform/create_transcript.svelte';
    import { btn, dbtn } from '../work/buttons'
    import Spinner from '../work/spinner.svelte'
    export let waveform;
    // export let parser;
    export let data_set_id;
    let import_transcript_auto = ldc_nodes.get_constraint('import_transcript_auto');
    // doesn't work for 2 channel
    let f = waveform.docid;
    if(f.match('/')) f = f.split('/')[1];
    if(f.match('_')) f = f.split('_')[0];
    else             f = f.split('.')[0];
    let data_set_file_name;
    if(import_transcript_auto){
        data_set_file_name = f;
    }
    let message = true;
    let name = '';
    // data_set_file_name = 'ML0152';
    const modal = {
        title: 'Create Kits',
        buttons: [
            [ 'Save', btn, cancel ]
        ]
    };
    function cancel(){ }
</script>

<style>
    #messagee {
        position: absolute;
        top: 50px;
        left: 300px;
        font-size: 24px;
    }
</style>

{#if data_set_file_name}
    {#if message}
        <div id="messagee">
            <span>Retrieving transcriptt {data_set_file_name}</span>
            <span class="mx-auto w-8 h-8"><Spinner /></span>
            <button class="{btn}" on:click={ () => message = false }><i class="fas fa-times"></i></button>
        </div>
    {/if}
    <CreateTranscript {waveform} {data_set_id} {data_set_file_name} autox={false} />
{:else}
    <Modal {...modal}>
        <div slot=summary>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM6.293 6.707a1 1 0 010-1.414l3-3a1 1 0 011.414 0l3 3a1 1 0 01-1.414 1.414L11 5.414V13a1 1 0 11-2 0V5.414L7.707 6.707a1 1 0 01-1.414 0z" clip-rule="evenodd" />
            </svg>
        </div>
        <div slot=body>
            <!-- <ModalHeader title="Upload Transcript" /> -->
            <CreateTranscript {waveform} {data_set_id} {data_set_file_name} />
        </div>
    </Modal>
{/if}
