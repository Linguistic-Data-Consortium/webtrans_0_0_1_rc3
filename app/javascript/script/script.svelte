<script>
    import { btn, cbtn, dbtn } from "../work/buttons"
    import { getp, postp, deletep, patchp } from "../work/getp";
    import Record from './record.svelte'
    import Upload from '../work/input_upload_auto.svelte'
    import Waveform from './waveform.svelte';
    import { check_line_of_code } from '../script/script'
    export let error;
    export let debug;
    let debug_text;
    let count_text;
    let counter = 0;
    let p = Promise.resolve('x');
    let lines;
    let line;
    let l = localStorage.getItem('script');
    if(l){
        l = l.split(' ');
        counter = Number(l[1]);
    }
    getp(window.location).then( (x) => {
        lines = x.code.split("\n");
        goto_next_line();
    } )
    function goto_next_line(){
        if(counter < lines.length){
            localStorage.setItem('script', `${window.location} ${counter}`)
            if(lines[counter].length){
                line = lines[counter];
                debug_text = `${counter+1}: ${line}\n`;
                p = new Promise( ( resolve ) => run_line(line, resolve) );
            }
            counter++;
            return new Promise( ( resolve ) => p.then( () => resolve(goto_next_line()) ) );
        }
        else{
            // return new Promise.resolve(lines);
        }
    }
    let go = () => null;
    function run_line(x, resolve){
        // setTimeout( () => resolve(), 2000 );
        line = check_line_of_code(x);
        console.log(line);
        if(line.command == 'kit'){
            window.location = '/workflows/10/work/3';
        }
        go = () => resolve();
    }
    let return_value;
    function returnf(e){
        console.log(e);
        return_value = e.detail;
    }
</script>

<style>
</style>

{#if debug}
    <div id="debug" class="absolute top-0 left-0 bg-green-200">
        <div>{counter}</div>
        <pre>{debug_text}</pre>
    </div>
{/if}

{#if error && error.error}
    <div class="col-2 mx-auto">
        {error.error}
    </div>
{:else if line}
    <div>
        {#if line.command == 'show'}
            <div>show</div>
        {:else if line == 'record'}
            <Record on:return={returnf}/>
        {:else if line == 'upload'}
            <Upload blob={return_value} />
        {:else if line == 'waveform'}
            <Waveform blob={return_value} />
        {/if}
    </div>
    <div class="col-2 mx-auto my-6">
        <button class="{btn}" on:click={go}>NEXT</button>
    </div>
{/if}
