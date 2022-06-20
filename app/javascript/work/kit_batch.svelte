<script>
    import Table from './table.svelte'
    import Modal from './modall.svelte'
    import Flash from './flash.svelte'
    import InputText from './input_text.svelte'
    import InputSelect from './input_select.svelte'
    import InputCheckbox from './input_checkbox.svelte'
    export const admin = false;
    export const lead_annotator = false;
    export let kit_batch_id;

    export let id;
    export let name;
    export let node_class_id;
    export let node_classes;
    // export let feature_files;
    export let constraints;
    export let features;

    let url = `/kit_batches/${kit_batch_id}`;
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

<div class="col-3 mx-auto">
    <div>ID: {id}</div>
    <form on:submit|preventDefault={()=>null}>
        <InputText {url} label=Name key=name value={name} />
        <InputSelect {url} label=Namespace key="node_class_id" value={node_class} values={node_classes} att=name />
    </form>
</div>
