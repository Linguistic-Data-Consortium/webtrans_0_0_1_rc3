<script>
    import { tick } from 'svelte'
    // import { getp, postp, deletep, patchp } from "./getp";
    import Upload from './input_upload.svelte'
    export let blob;
    function sourcefile(){
        // upload_helper3: ->
        tick().then( () => {
            upload();
        } );
    }
    function upload(){
        if(!blob) return;
        const input = document.getElementById('source_file');
        console.log('input')
        const url = input.dataset.directUploadUrl;
        // # blob = new Blob(['testing'], {type : 'text/plain'})
        // const blob = window.ldc.vars.blob;
        blob.filename = 'x';
        console.log(blob)
        let base;
        if(false) //$('.Root').length is 1 and $('.Root').data().obj
            base = false; //$('.Root').data().obj.user_id.toString().padStart(10,'0')
        else
            base = 'none';
        let d = new Date();
        d = d.toISOString().replace(/[-:]/g,'').replace(/\.\d+Z/,'Z');
        let blob_name = 'x'
        blob.name = `${base}-${d}-${blob_name}.wav`;
        // console.log blob
        const upload = new ActiveStorage.DirectUpload(blob, url);
        console.log('upload');
        // # reader = new FileReader()
        // # reader.addEventListener('loadend', (e) ->
        // #     text = e.srcElement.result
        // #     console.log text
        // # )
        // # reader.readAsText  blob
        const create = () => {
            upload.create( (error, blob) => {
                if(error)
                    console.log('error');
                else{
                    console.log('blob');
                    console.log(blob);
                    const o = {
                        source: {
                            file: blob.signed_id,
                            uid: blob.signed_id
                        }
                    };
                    console.log(o);
                    postp('/sources', o).then( (data) => {
                        console.log('post');
                        console.log(data);
                        message = `upload complete for ${blob.filename}`;
                        // that.upload_callback data
                    } );
                }
            } )
        };
        // if(window.ldc_annotate)
        //     ldc_annotate.add_callback( () => create() );
        // else
            create();
    }
    let message = 'uploading...';
</script>

<style>
    .hidden {
        display: none;
    }
</style>

{message}

<div class="hidden">
    <Upload on:sourcefile={sourcefile} />
</div>
