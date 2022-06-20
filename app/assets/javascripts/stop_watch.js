var clsStopwatch = function () {
    var startAt = 0;
    var lapTime = 0;

    var now = function () {
        return (new Date()).getTime();
    };

    var pad = function(num, size) {
        var s = "0000" + num;
        return s.substr(s.length - size);
    };
    
    var formatTime = function(time) {
        var h = m = s = ms = 0;
        var newTime = '';
    
        h = Math.floor(time / (60 * 60 * 1000));
        time = time % (60 * 60 * 1000);
    
        m = Math.floor(time / (60 * 1000));
        time = time % (60 * 1000);
    
        s = Math.floor( time / 1000 );
    
        newTime = pad(m, 2)+ ':' + pad(s, 2);
        return newTime;
    };
    
    this.start = function () {
        startAt = startAt ? startAt : now();
    };
    
    this.stop = function () {
        lapTime = startAt ? lapTime + now() - startAt : lapTime;
        startAt = 0;
    };
    
    this.reset = function () {
        lapTime = startAt = 0;
    };
    
    this.time = function () {
        return lapTime + (startAt ? now() - startAt : 0);
    };
    
    this.update = function(sel){
        var that = this;
        $(sel).html(formatTime(that.time()));
    };

};
