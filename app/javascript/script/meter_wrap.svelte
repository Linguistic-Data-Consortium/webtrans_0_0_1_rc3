<!--
The Meter component was best defined with a property that's changed directly.
However, sometimes you need a setter function, hence this component.
-->
<script>
    import Meter from './meter.svelte'
    let v = 0;
    export function set(x) { v = x; }
    export let clipped;
</script>

<Meter {v} {clipped} />
