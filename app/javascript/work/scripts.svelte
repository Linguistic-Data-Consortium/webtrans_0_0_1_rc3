<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { tick } from 'svelte';
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import Table from './table.svelte'
    import Modal from '../modal.svelte'
    import Flash from './flash.svelte'
    import Script from './script.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    export let help;
    export let admin = false;
    export let portal_manager = false;
    export let project_manager = false;
    let category;
    let name;
    let p;
    function get(){ p = getp('/scripts') }
    get();
    let columns = [
        [ 'Name', 'name', 'col-1' ],
        [ 'Description', 'description', 'col-1' ],
        [ 'Type', 'type', 'col-1' ],
    ];
    const createm = {
        name: 'create_script_modal',
        title: 'Create script',
        h: '',
        buttons: [
            [ 'Create', cbtn, create ]
        ]
    };
    const deletem = {
        name: 'delete_script_modal',
        title: 'Delete script',
        h: '',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ]
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
                script_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
            get();
        }
    }
    function create(){
        postp(
            "/scripts",
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/scripts/${script_id}`
        ).then(response);
    }
    let script_id;
    let script_index;
    let pp;
    function open(){
        pp = getp(`/scripts/${script_id}`)
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
    tick().then(()=>{
        // project_id = 57;
        // project_id = 33;
        // script_id = 1;
        // open();
        
    });
</script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>scripts</p>
    </div>
</Help>

{#await p}
    <div class="mx-auto w-8 h-8"><Spinner /></div>
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" on:click={back}>Return to Script list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Script {help} {admin} {project_manager} {script_id} {...v} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            <div>All scripts</div>
            {#if script_id && script_index}
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
                            This will delete the script {script_index[script_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {:else}
                Select a script in the table for more options.
            {/if}
            {#if project_manager}
                <Modal {...createm}>
                    <div slot=summary>
                        Create script
                    </div>
                    <div slot=body>
                         <form on:submit|preventDefault={()=>null}>
                             <InputText label=Name key=name bind:value={name} />
                        </form>
                    </div>
                </Modal>
            {/if}
        </div>
        <Table bind:selected={script_id} bind:index={script_index} {columns} rows={v} use_filter={true} key_column=id height=400 on:selected={selected} />
    {/if}
{/await}
