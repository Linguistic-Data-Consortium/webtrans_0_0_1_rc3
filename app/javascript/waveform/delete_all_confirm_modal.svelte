<script>
    import Modal from '../modal.svelte'
    import { btn, dbtn } from '../work/buttons'
    export let waveform;
    const deletem = {
        name: 'delete_all_confirm_modal',
        title: 'Delete ALL segments',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ],
        start_with_button: false
    };
    function destroy(){
        waveform.delete_all();
    }
</script>

<style>
</style>

<Modal {...deletem} open={true} on:close >
    <div slot=summary>
        Remove Userx
    </div>
    <div slot=body>
        This will remove ALL segments, are you sure you want to do this?
    </div>
</Modal>
