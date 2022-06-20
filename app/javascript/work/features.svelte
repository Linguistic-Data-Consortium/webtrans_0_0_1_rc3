<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Modal from '../modal.svelte'
    import Flash from './flash.svelte'
    import Feature from './feature.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    export let help;
    export let admin = false;
    export let lead_annotator = false;
    let category;
    let name;
    let p;
    function get(){ p = getp('/features') }
    get();
    let columns = [
        [ 'Category', 'category', 'col-1' ],
        [ 'Feature', 'name', 'col-1' ],
        [ 'Value', 'value', 'col-1' ],
        [ 'Label', 'label', 'col-2' ],
        [ 'Description', 'description', 'col-8' ]
    ];
    const createm = {
        name: 'create_feature_modal',
        title: 'Create feature',
        h: '',
        buttons: [
            [ 'Create', cbtn, create ]
        ]
    };
    const deletem = {
        name: 'delete_feature_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete feature',
        h: ''
    };
    let flash_type = null;
    let flash_value;
    function response(data){
        if(data.error){
            flash_type = 'error';
            flash_value = data.error.join(' ');
        }
        else{
            flash_type = 'success';
            if(data.deleted){
                flash_value = data.deleted;
                feature_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
            get();
        }
    }
    function create(){
        postp(
            "/features",
            { category: category, name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/features/${feature_id}`
        ).then(response);
    }
    let feature_id;
    let feature_index;
    let pp;
    function open(){
        pp = getp(`/features/${feature_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    let style;
    let timeout;
    function selected(e){
        style = `position: absolute; left: ${e.detail.pageX-20}px; top: ${e.detail.pageY+20}px; z-index: 10`;
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout( () => style = null, 2000);
    }
</script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>features</p>
    </div>
</Help>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" on:click={back}>Return to Feature list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Feature {help} {admin} {lead_annotator} {feature_id} {...v} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            <div>All features</div>
            {#if feature_id && feature_index}
                <div>
                    <button class="{btn}" on:click={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div><button class="{btn}" on:click={open}>Open</button></div>
                    </div>
                {/if}
                {#if admin}
                    <Modal {...deletem}>
                        <div slot=summary>
                            Delete
                        </div>
                        <div slot=body>
                            This will delete the feature {feature_index[feature_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {:else}
                Select a feature in the table for more options.
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    <div slot=summary>
                        Create feature
                    </div>
                    <div slot=body>
                         <form on:submit|preventDefault={()=>null}>
                             <InputText label=Category key=category bind:value={category} />
                             <InputText label=Name key=name bind:value={name} />
                        </form>
                    </div>
                </Modal>
            {/if}
        </div>
        <Table bind:selected={feature_id} bind:index={feature_index} {columns} rows={v} use_filter={true} key_column=id height=400 on:selected={selected} />
    {/if}
{/await}
