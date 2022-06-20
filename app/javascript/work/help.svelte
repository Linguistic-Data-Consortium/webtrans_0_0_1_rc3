<script>
    export let help;
</script>

<style>
</style>

{#if help}
    <div class="text-center bg-blue-200 my-2 rounded-full">
    	<slot name="content">empty</slot>
    </div>
{/if}
