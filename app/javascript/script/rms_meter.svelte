<script>
    import Meter from 'script/meter'
    let rms = 0;
    export function analyze(time_domain, freq_domain){
        let sum = 0;
        for(let i = 0; i < time_domain.length; i++){
            let v = Math.abs(time_domain[i]);
            sum += v * v;
        }
        rms = Math.sqrt(sum / time_domain.length);
    }
</script>

<Meter v={rms} clipped={.99} />
