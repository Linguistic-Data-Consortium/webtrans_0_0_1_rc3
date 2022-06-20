<script>
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import InputText from './input_text.svelte'
    import InputSelect from './input_select.svelte'
    // export let help;
    export const admin = false;
    export const lead_annotator = false;

    export let id;
    export let name;
    export let description;
    export let type;
    export let types;

    let url = `/workflows/${id}`;
    console.log('check');
</script>

<style>
</style>

<div class="col-3 mx-auto">
    <div>ID: {id}</div>
    <form on:submit|preventDefault={()=>null}>
        <InputText {url} label=Name key=name value={name} />
        <InputText {url} label=Description key=description value={description} textarea={true} />
        <InputSelect {url} label=Type key=type value={type} values={types} />
    </form>
</div>
