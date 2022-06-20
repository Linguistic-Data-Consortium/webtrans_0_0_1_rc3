<script>
    import { getp, postp, deletep, patchp } from "./getp";
    import { getSignedUrlPromise } from './aws_helper';
    import { get_promises } from '../work/services'
    export function sb(){ sp = getp(base) }
    // sp = getp(base + '/schema/sad.schema.json');
    // sp = ldc_nodes.getp_simple(base + '/schema/sad.schema.json');
    // sp.then((x) => { console.log('pppppp'); console.log(x) });
    // let urls = window.gdata('.Root').resources.urls;
    // let url = Object.keys(urls)[0];
    export let url;
    getSignedUrlPromise('coghealth', url).then( (fn) => get1(fn) );
    // url = 'https://coghealth.s3.amazonaws.com/' + url;
    // get1(url);
    let service_promise;
    let output_promise;
    function get1(fn){
        const o = { type: 'sad', data: { audio: fn } };
        const set_sp = (x) => service_promise = x;
        const set_op = (x) => output_promise = x;
        get_promises(set_sp, set_op, o);
    }
</script>

<style>
</style>

<pre>
    {#if service_promise}
        {#await service_promise}
            loading
        {:then value}
            <!-- <JSONTree {value} /> -->
            {JSON.stringify(value, null, 2)}
        {/await}
    {/if}
</pre>
<pre>
    {#if output_promise}
        {#await output_promise}
            loading
        {:then value}
            <!-- <JSONTree {value} /> -->
            {JSON.stringify(value, null, 2)}
        {/await}
    {/if}
</pre>
