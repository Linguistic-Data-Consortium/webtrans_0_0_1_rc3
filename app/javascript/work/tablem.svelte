<script>
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import ModalHeader from './modall_box_header.svelte'
    import { btn, dbtn } from './buttons'
    export let name = '';
    export let columns;
    export let rows;
    export let use_filter = false;
    export let key_column;
    export let height;
    export let column_border = false;
    export let download;
    export function get_selected_key(){
        return selected;
    }
    export function make_copy(table, map, key1, key2){
        let a = [];
        for(let x of table){
            let h = {};
            a.push(h);
            for(let y in x){
                h[y] = x[y];
            }
            if(map){
                let v = h[key2];
                if(v){
                    v = map[v];
                    if(v) h[key1] = v;
                }
            }
        }
        return a;
    }
    let sorti = -1;
    let sortd = true;
    let sort_key;
    function sort3(a, b){
        return sort1(a[sort_key].replace(/<.+?>/g, ''), b[sort_key].replace(/<.+?>/g, ''));
    }
    function sort2(a, b){
        return sort1(a[sort_key], b[sort_key]);
    }
    function sort1(a, b){
        return sort4(String(a).toLowerCase(), String(b).toLowerCase());
    }
    function sort4(a, b){
        if(a < b){
            if(sortd) return -1;
            else      return 1;
        }
        if(a > b){
            if(sortd) return 1;
            else      return -1;
        }
        return 0;   
    }
    function header(){
        let i = this.dataset.i;
        if(i == sorti){
            sortd = ! sortd;
        }
        else{
            sorti = i;
            sortd = true;
        }
        if(sorti > -1){
            sort_key = columns[sorti][1];
            let c = make_copy(rows);
            if(columns[sorti][3] == 'html') c.sort(sort3);
            else                            c.sort(sort2);
            rows = c;
        }
        else{
        }
    }
    export let selected = null;
    function click_select(e){
        selected = this.dataset.key;
        dispatch('selected', e);
    }
    let text_red;
    export function set_text_red(x){
        text_red = x;
    }
    let filter = '';
    let matched = [];
    function match(x, i){
        if(i == 0) matched = [];
        let b = match3(x);
        if(b) matched.push(x);
        return b;
    }
    function match3(x){
        if(filter == '') return match2(x);
        let re = new RegExp(filter, 'i');
        for(let i = 0; i < columns.length; i++){
            let k = columns[i][1];
            if(x[k] && String(x[k]).match && String(x[k]).match(re)) return match2(x);
        }
        return false;
    }
    export let index = new Map();
    if(key_column){
        for(let x of rows){
            index.set(x[key_column], x);
        }
    }
    let use_menu_filters = false;
    let filters = {};
    let all = {}
    for(let x of columns){
        if(x[3] == 'filter'){
            use_menu_filters = true;
            filters[x[1]] = 'any';
            all[x[1]] = [ 'any' ];
        }
    }
    function handleSubmit(){}
    for(let x of rows){
        for(let y of columns){
            let key = y[1];
            if(y[3] == 'filter'){
                if(!all[key].includes(x[key])){
                    all[key].push(x[key]);
                }
            }
        }
    }
    function match2(x){
        for(let y of columns){
            let key = y[1];
            if(y[3] == 'filter'){
                if(filters[key] != 'any' && x[key] != filters[key]){
                    return false;
                }
            }
        }
        return true;
    }
    export function match_attempted(){
        for(let y of columns){
            let key = y[1];
            if(y[3] == 'filter'){
                if(filters[key] != 'any'){
                    return true;
                }
            }
        }
        return filter.length > 0;
    }
    export function get_matched(){
        return matched;
    }
    let tsv;
    let include_headers;
    let include_full;
    let url;
    let link;
    let filename;
    function download_reset(){
        tsv = 'empty';
        include_headers = false;
        include_full = null;
        url = null;
    }
    function downloadf(){
        let a = [];
        let b = [];
        if(include_headers){
            for(let y of columns){
                b.push(y[0]);
            }
            a.push(b.join('\t'))
        }
        let rs;
        if(include_full == 'yes'){
            rs = rows;
        }
        else if(include_full == 'no'){
            rs = matched;
        }
        for(let x of rs){
            b = [];
            for(let y of columns){
                b.push(x[y[1]]);
            }
            a.push(b.join('\t'));
        }
        tsv = a.join('\n') + "\n";
        url = URL.createObjectURL(new Blob([tsv], {type : 'text/tab-separated-values'}));
        link.href = url;
    }
</script>

<style>
    .odd {
      background: #eee;
    }
    #preview {
        width: 800px;
        height: 200px;
        overflow: auto;
    }
</style>


<div>
    {#if use_filter}
        <div class="flex justify-around">
            <div class="float-left">
                {rows.length} row{rows.length == 1 ? '' : "s"}
            </div>
            {#if download}
                <div class="float-right">
                    <details class="details-reset details-overlay details-overlay-dark">
                        <summary class="{btn}" on:click={download_reset}>
                            <i class="fa fa-download"></i>
                        </summary>
                        <details-dialog class="Box Box--overlay anim-fade-in fast">
                            <ModalHeader title="Download Table as File" />
                            <div class="Box-body">
                                <div>
                                    <p>You can download the full table or a filtered form of it as a tab separated file.</p>
                                    <p>Note that the original ordering of the table isn't saved once you sort the table by clicking the column headers.  If you've sorted the table, that's the "full" form.</p>
                                </div>
                                <form class="flex">
                                    <label>
                                        <input type=radio bind:group={include_full} value=yes >
                                        Full Table
                                    </label>
                                    <label>
                                        <input type=radio bind:group={include_full} value=no  >
                                        Matched Rows Only
                                    </label>
                                    <label>
                                        <input type=checkbox bind:checked={include_headers}>
                                        Include headers
                                    </label>
                                    <label>
                                        <input class="input-sm" type=text bind:value={filename} placeholder="filename">
                                    </label>
                                    <!-- svelte-ignore a11y-missing-attribute -->
                                    <a bind:this={link} download={filename}>{ url ? "Download" : ""}</a>
                                    {#if !url}
                                        <button type="button" class="{btn}"   on:click={downloadf}>Create</button>
                                    {/if}
                                </form>
    <!--                             <div>
                                    <button type="button" class="{btn}"   on:click={downloadf}>Full Table</button>
                                    <button type="button" class="{btn}"   on:click={downloadm}>Matched Rows Only</button>
                                </div>
     -->                            <div>Preview</div>
                                <pre id="preview" class=border>
                                    {tsv}
                                </pre>
                            </div>
                            <div class="Box-footer text-right">
                                <!-- <button type="button" class="{btn}"   data-close-dialog on:click={downloadf}>download</button> -->
                            </div>
                        </details-dialog>
                    </details>
                </div>
            {/if}
            <div class="float-right">
                {matched.length} matched <input class="form-control" bind:value={filter} placeholder="filter">
            </div>
            {#if use_menu_filters}
                <div class="float-right px-4">
                    <form on:submit|preventDefault={handleSubmit}>
                        {#each columns as x}
                            {#if x[3] == 'filter'}
                                <label>
                                    {x[0]}
                                    {filters[x[1]]}
                                    <select bind:value={filters[x[1]]}>
                                        {#each all[x[1]] as y}
                                            <option value={y}>{y}</option>
                                        {/each}
                                    </select>
                                </label>
                            {/if}
                        {/each}
                    <form>
                </div>
            {/if}
        </div>
    {/if}
    <div class={`overflow-y-auto ${name}`} style="height: {height}px">
        <div class="d-table col-12 position-sticky top-0">
            {#each columns as x, i}
                <div class="d-table-cell {x[2]} p-2 {i == sorti ? 'color-bg-warning' : 'color-bg-info'}"
                on:click={header} data-i={i}>
                    {x[0]}
                    {#if sorti == i}
                        {#if sortd}
                            <span><i class="fas fa-angle-down"></i></span>
                        {:else}
                            <span><i class="fas fa-angle-up"></i></span>
                        {/if}
                    {/if}
                </div>
            {/each}
        </div>
        {#each rows as x, i}
            {#if match(x, i) && filter.length > -1 && filters}
                <div class="
                    d-table col-12
                    {x[key_column] == selected ? 'color-bg-success': '' }
                    {x[key_column] == text_red ? 'color-text-danger': '' }
                    {i % 2 ? 'odd' : ''}
                "
                on:click={click_select} data-key={x[key_column]}>
                    {#each columns as y, i}
                        <div class="d-table-cell {y[2]} p-2 break-word {column_border ? "border-x" : ""}">
                            {#if y[3] == 'html'}
                                {@html x[y[1]]}
                            {:else if y[3] == 'button'}
                                <button class="{btn}" title={x[y[1]]}>{x[y[1]]}</button>
                            {:else if y[3] == 'f'}
                                <div on:click={ y[4](x, y[1]) }>{x[y[1]]}</div>
                            {:else if x[y[1]]}
                                {x[y[1]]}
                            {:else}
                                <i>empty</i>
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}
        {/each}
    </div>
</div>
