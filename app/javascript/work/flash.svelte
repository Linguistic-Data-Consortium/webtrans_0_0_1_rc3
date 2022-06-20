<script>
    export let flash_type;
    export let flash_value;
</script>

<style>
</style>

{#if flash_type}
    <div class="text-center flash flash-{flash_type} my-2">
        {flash_value}
        <button type=button class="closex flash-close js-flash-close" on:click={() => flash_type = null}>
            <i class="fa fa-times"></i>
        </button>
    </div>
{/if}
