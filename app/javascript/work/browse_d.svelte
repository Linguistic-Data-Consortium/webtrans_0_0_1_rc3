<script>
    import { getp, postp, deletep, patchp } from "./getp";

    import Table from './table.svelte'
		import { listObjectsV2, headObject } from './aws_helper';
    import Spinner from './spinner.svelte'
    // export let sel2;
    // export let sel3;
    // export let browser;
    export let bucket;
    // export let tasks;
    let hidden1 = false;
    let hidden11 = true;
    let hidden2 = true;
    let hidden22 = true;
    let hidden3 = true;
    let hidden4 = true;
    let hidden5 = true;
    let hidden55 = true;
    let nfiles = 0;
    let nfiles_in_bucket = 0;
    let nkits = 0;
    let search_for = [];
    // export function step1(){
    //     hidden1 = false;
    //     // browser.browse();
    // }
    // export function step2(n){
    //     hidden2 = false;
    //     nfiles = n;
    // }
    // export function step4(n){
    //     hidden4 = false;
    //     nfiles_in_bucket = n;
    // }
    export function step5(n){
        hidden5 = false;
        nkits = n;
    }
    let p;

    console.log('PP');
    function f(data){
        console.log('333333');
        // console.log(data);
        // bucket = that.bucket
        let ps = [];
        for(let x of data.Contents){
            // console.log x.Key
            let params = {
                Bucket: bucket,
                Key: x.Key
            };
            // s3.headObject params, (err, data) ->
            //     if err
            //         console.log(err, err.stack)
            //     else 
            //         # if x.Key is 'HVGZ6nw2nRfFVdZk1F3BNqbf'
            ps.push(headObject(params).promise());
        }
        return Promise.all(ps).then((values) => {
            let found = [];
            // $(that.sel3).append "<div>found #{values.length} files in bucket</div>"
            // nfiles_in_bucket = values.length
            // console.log "found #{values.length} files in bucket"
            for(let data of values){
                let filename = null;
                let key = data.$response.request.params.Key;
                if(bucket == 'speechbiomarkers'){
                    if(data.Metadata.uid){
                        filename = data.Metadata.uid;
                    }
                }
                else{
                    if(bucket == 'labov'){
                        filename = key;
                    }
                    else{
                        filename = key;
                    }
                }
                if(filename){
                    found.push({
                        type: 'audio',
                        location: 's3',
                        source_id: 'aws',
                        filename: filename,
                        key: key
                    });
                }
            }
            console.log('FOUND');
            console.log(found);
            return found;
        });
    }
    p = Promise.resolve(listObjectsV2().promise().then(f));
    let columns = [
        // [ 'Type', 'type', 'col-1' ],
        [ 'Filename', 'filename', 'col-1' ]
        // [ 'Location', 'location', 'col-1' ],
        // [ 'Key', 'key', 'col-1' ]
        // [ 'Action', 'action', 'col-1' ]
    ]
    // p.then((x) => console.log(x));
</script>

<style>
</style>

<div>
    {#await p}
        <div>searching bucket {bucket}</div>
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then rows}
        <div>found {rows.length} files in bucket</div>
        <Table {columns} {rows} use_filter={true} key_column=key height=500 />
    {/await}
</div>
