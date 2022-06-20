<script>
    export let parser;
    let files;
    function upload(){
        const r = new FileReader();
        let o = null;
        r.onload = function(e){
            parser.parse(e.target.result);
        }
        r.readAsText(files[0]);
    }
</script>

<div id=browse_b>
    <div>upload a transcript</div>
    <div>
        <input type="file" bind:files>
        {#if files && files[0]}
            <div>{files[0].name}</div>
            <div><button on:click={upload}>upload</button></div>
        {/if}
    </div>
</div>
