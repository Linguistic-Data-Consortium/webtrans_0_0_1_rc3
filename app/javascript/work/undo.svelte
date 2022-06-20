<script>
    import Table from './table.svelte'
    let p = null;
    export function undo(){
        p = window.gdatap('.Root').then( (x) => getp(`/kits/${x.obj.kit_id}/undo`) );
        let stack = {};
        let tables = new Map();
        p.then( (x) => {
            let last_iid = 0;
            for(let y of x){
                if(y.message == 'new' || y.message == 'add'){
                    let children = y.value.split(',').map( x => x.split(':')[0] );
                    let ncid = children[0];
                    if(!tables.has(ncid)) tables.set(ncid, []);
                    let item = [ [ last_iid+0, ncid ] , [] ];
                    last_iid++;
                    tables.get(ncid).push(item);
                    for(let i = 1; i < children.length; i++){
                        item[1].push([ [ last_iid+0, children[i] ], []]);
                        last_iid++;
                    }
                }
                if(y.message == 'change'){
                    if(!stack[y.iid]) stack[y.iid] = [];
                    stack[y.iid].push(y.value)
                }
            }
            let g = window.gdata('.Root').obj.inverted_grammar;
            for(let [ k, v ] of tables){
                console.log(k);
                let sel = '.' + g[k].name.split(':')[1];
                let all_found = true;
                document.querySelectorAll(sel).forEach( (x) => {
                    let found = false;
                    let iid = x.id.split('-')[1];
                    for(let item of v){
                        if(String(item[0][0]) == iid){
                            found = true;
                            break;
                        }
                    }
                    if(!found) all_found = false;
                })
                console.log(`${sel} all found: ${all_found}`);
                console.log(k == 'x');
            }
            console.log(tables);
        });
    }
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'TID', 'transaction_id', 'col-1' ],
        [ 'PID', 'parent_id', 'col-1' ],
        [ 'User', 'user_id', 'col-1' ],
        [ 'Task', 'task_id', 'col-1' ],
        [ 'Tree', 'tree_id', 'col-1' ],
        [ 'IID', 'iid', 'col-1' ],
        [ 'Message', 'message', 'col-1' ],
        [ 'Value', 'value', 'col-4' ]
    ];
    let ann_id;
    let ann_index;
    function selected(){}
</script>

<style>
</style>

{#if p}
    {#await p}
        waiting
    {:then rows}
        <Table bind:selected={ann_id} bind:index={ann_index} {columns} {rows} use_filter={true} key_column=id height=400 on:selected={selected}/>
    {/await}
{/if}
