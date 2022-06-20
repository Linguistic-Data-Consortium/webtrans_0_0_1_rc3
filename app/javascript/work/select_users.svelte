<script>
    import { getp } from './getp'
    import Modal from '../modal.svelte'
    import { btn, dbtn } from './buttons'
    export let urlf;
    export let create;
    export let auto2;
    const createm = {
        name: 'create_task_user_modal',
        title: 'Add Member',
        h: '',
        buttons: [
            [ 'Create', btn, create ]
        ]
    };
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'User', 'name', 'col-2' ],
    ];
    let name;
    function auto3(x){
        name = x.name;
        createm.open = false;
        auto2(x);
    }
    let p = Promise.resolve([]);
    let timeout;
    function auto(name){
        if(!name || name.length < 3){
            p = Promise.resolve([]);
            return;
        }
        if(typeof(urlf) == 'object'){
            p = Promise.resolve(urlf);
            return;
        }
        if(timeout) clearTimeout(timeout);
        timeout = setTimeout(() => {
            p = getp(urlf(name));
        }, 500);
    }
    $: auto(name);
</script>

<Modal {...createm}>
    <div slot="summary">
        Add User
    </div>
    <div slot="body">
        <!-- <Table bind:selected={xtask_id} bind:index={xtask_index} {columns} rows={project_users} use_filter={true} key_column=id height="96" on:selected={selected} /> -->
        <div>
            <div class="grid grid-cols-2">
                <div>
                    Name
                    <input type=text bind:value={name}/>
                </div>
                <div>
                    {#await p}
                    {:then v}
                        {#each v as x}
                            {#if x.name.includes(name)}
                                <button class="{btn}" on:click={ () => auto3(x) }>{x.name}</button>
                                <!-- <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                  <path d="M8 9a3 3 0 100-6 3 3 0 000 6zM8 11a6 6 0 016 6H2a6 6 0 016-6zM16 7a1 1 0 10-2 0v1h-1a1 1 0 100 2h1v1a1 1 0 102 0v-1h1a1 1 0 100-2h-1V7z" />
                                </svg> -->
                            {/if}
                        {/each}
                    {/await}
                </div>
            </div>
        </div>
    </div>
</Modal>
