<script>
    export let label;
    export let value;
</script>

<div class="form-group">
    <div class="form-group-header">
        <label>{label}</label>
    </div>
    <div class="form-group-body">
        <input type=text class="form-control" bind:value={value} />
    </div>
</div>
