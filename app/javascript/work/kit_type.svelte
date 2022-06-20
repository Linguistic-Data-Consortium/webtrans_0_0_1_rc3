<script>
    import Table from './table.svelte'
    import Modal from './modall.svelte'
    import Flash from './flash.svelte'
    import InputText from './input_text.svelte'
    import InputSelect from './input_select.svelte'
    import InputCheckbox from './input_checkbox.svelte'
    export let admin = false;
    export let lead_annotator = false;
    let unused = admin && lead_annotator;
    export let kit_type_id;

    export let id;
    export let name;
    export let node_class_id;
    export let node_classes;
    // export let feature_files;
    export let constraints;
    export let features;

    let url = `/kit_types/${kit_type_id}`;
    let node_class;
    for(let x of node_classes){
        if(x.id == node_class_id){
            node_class = x;
            break;
        }
    }

    let constraintb = {};
    for(let x of features){
        if(x.name == x.value){
            constraintb[x.name] = constraints[x.name] == x.name;
        }
        else{
            constraintb[x.name] = constraints[x.name];
        }
    }
</script>

<style>
</style>

<div class="w-1/2 mx-auto">
    <div>ID: {id}</div>
    <form on:submit|preventDefault={()=>null}>
        <InputText {url} label=Name key=name value={name} />
        <InputSelect {url} label=Namespace key="node_class_id" value={node_class} values={node_classes} att=name />
        {#each features as x}
            {#if x.name == x.value}
                <InputCheckbox {url} label={x.label} key={x.name} value={constraintb[x.name]} meta="constraints" />
            {:else if x.value == 'comma'}
                <InputText {url} label={x.label} key={x.name} value={constraintb[x.name]} meta="constraints" split="," />
            {:else}
                <InputText {url} label={x.label} key={x.name} value={constraintb[x.name]} meta="constraints" />
            {/if}
        {/each}
    </form>
</div>
