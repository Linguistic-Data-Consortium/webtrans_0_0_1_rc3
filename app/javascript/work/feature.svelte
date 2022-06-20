<script>
    import { getp, postp, deletep, patchp } from "./getp";
    import Help from './help.svelte'
    import InputText from './input_text.svelte'
    // export let help;
    export const admin = false;
    export const lead_annotator = false;

    export let id;
    export let category;
    export let name;
    export let value;
    export let label;
    export let description;

    let url = `/features/${id}`;
</script>

<style>
</style>

<div class="col-3 mx-auto">
    <div>ID: {id}</div>
    <form on:submit|preventDefault={()=>null}>
        <InputText {url} label=Category key=category value={category} />
        <InputText {url} label=Name key=name value={name} />
        <InputText {url} label=Value key=value value={value} />
        <InputText {url} label=Label key=label value={label} />
        <InputText {url} label=Description key=description value={description} textarea={true} />
    </form>
</div>
