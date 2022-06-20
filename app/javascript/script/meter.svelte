<script>
    export let v;
    export let clipped;
    let maxv = 0;
    $: if(v > maxv) maxv = v;
    $: w = v * 100;
    $: x = maxv * 100;
    $: textx = (maxv + .1) * 100;
    $: text = Math.round(maxv * 10000) / 100;
    $: fill = maxv > clipped ? 'red' : 'green';
</script>

<style>
    #rect1 {
        fill: green;
        opacity: 0.5;
    }
    #rect3 {
        fill: white;
        stroke-width: 1;
        stroke: green;
    }
    #text1 {
        fill: green;
    }
</style>

<div>
    <svg width="100%" height="50">
        <rect id="rect3" width="100%" height="100%" />
        <rect id="rect1" width="{w}%" height="100%" />
        <rect id="rect2" width="10" height="100%" x="{x}%" fill={fill} />
        <text id="text1" y="25"                   x="{textx}%">{text}</text>
    </svg>
</div>
