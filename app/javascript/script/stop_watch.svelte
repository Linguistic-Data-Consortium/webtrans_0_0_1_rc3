<script>

    let startAt = 0;
    let lapTime = 0;

    let now = function () {
        return (new Date()).getTime();
    };

    let pad = function(num, size) {
        let s = "0000" + num;
        return s.substr(s.length - size);
    };
    
    function formatTime(time){
        let h = 0;
        let m = 0;
        let s = 0;
        let ms = 0;
        let newTime = '';
    
        h = Math.floor(time / (60 * 60 * 1000));
        time = time % (60 * 60 * 1000);
    
        m = Math.floor(time / (60 * 1000));
        time = time % (60 * 1000);
    
        s = Math.floor( time / 1000 );
    
        newTime = pad(m, 2)+ ':' + pad(s, 2);
        return newTime;
    };
    
    let interval;
    
    export function start() {
        startAt = startAt ? startAt : now();
        update();
        interval = setInterval( update, 500 );
    };
    
    export function stop() {
        lapTime = startAt ? lapTime + now() - startAt : lapTime;
        startAt = 0;
        update();
        if(interval) clearInterval(interval);
    };
    
    export function reset() {
        lapTime = startAt = 0;
        update();
    };
    
    function time(){
        return lapTime + (startAt ? now() - startAt : 0);
    };
    
    let display;
    export function update(){
        display = formatTime(time());
    };

</script>

<style>
</style>

{display}
