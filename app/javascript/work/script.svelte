<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { make_patch } from "./patch";
    import Help from './help.svelte'
    import InputText from './input_text.svelte'
    import InputSelect from './input_select.svelte'
    import { check_line_of_code } from '../script/script'
    export let help;
    export let admin = false;
    export let portal_manager = false;
    export let project_manager = false;

    export let id;
    export let name;
    export let description;
    export let code;
    export let rgroup_id;
    export let wgroup_id;
    export let xgroup_id;
    export let script_id;
    export let user_id;

    let url = `/scripts/${id}`;
    
    let c;
    $: update(c);
    function update(c){
        // console.log(c);
    }
    function kp(e){
        if(e.key == 'Enter'){
            if(current_line){
                let a = code.split("\n");
                a[current_line-1] = c;
                patch('code', a.join("\n"));
                current_line = null;
            }
            else{
                patch('code', code + "\n" + c);
            }
        }
    }
    let flash_type;
    let flash_value;
    const patch = make_patch(
        url,
        (error) => {
            flash_type = 'error';
            flash_value = error;
        },
        (message, v) => {
            flash_type = 'success';
            flash_value = message;
            code = v;
        }
    )
    let current_line;
    if(code) current_line = code.split("\n").length;
    $: {
        if(current_line) c = code.split("\n")[current_line-1];
        else             c = '';
    }
    let ok = false;
    $: ok = check_line_of_code(c);
    function run(){
        window.open(url);
    }
</script>

<style>
</style>

<div class="grid grid-cols-2">
    <div class="pr-4">
        <div>ID: {id}</div>
        <div>
            <InputText {url} label=Name key=name value={name} />
            <InputText {url} label=Description key=description value={description} textarea={true} />
            <InputText {url} label=XGroupID key=xgroup_id value={xgroup_id} />
        </div>
    </div>
    <!-- <div class="float-left col-4">
        <div>text</div>
    </div> -->
    <div>
        {#if code}
            {#each code.split("\n") as line, i}
                <pre class="{i + 1 == current_line ? "bg-blue-200" : ''}" on:click={() => current_line = i+1}>{i+1}: {line}</pre>
            {/each}
        {/if}
        <input
            type=text
            class="{ok ? 'bg-green-200' : 'bg-red-200' } my-4 focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
            bind:value={c}
            on:keypress={kp}
        />
        {#if flash_value}
            <div>{flash_value}</div>
        {/if}
        <button class="{btn}" on:click={run}>run</button>
    </div>
</div>
