document.addEventListener("DOMContentLoaded", function () {

    // ldc_source.start_level_testing();
/**
    //canvas
    var canvas = document.querySelector('#volume');

    var canvasContext = canvas.getContext("2d");

    //main section
    var mainSection = document.querySelector(".recording");

    //Start Button
    var start = document.querySelector(".start");

    //constraints for making sure only we only get audio stream
    var Constraint = window.constraints = {
        audio: true,
        video: false
    }

    navigator.mediaDevices.getUserMedia(Constraint)                     //to get user persimssion to use mic
        .then(function (stream) {
            // Create an AudioNode from the stream.


            start.onclick = function () {

                var nextPage = document.querySelector(".nextPage");
                if(nextPage){
                    nextPage.remove();
                }

                var audioContext = new (window.AudioContext || webkitAudioContext)();
                var source = audioContext.createMediaStreamSource(stream);
                // Create a new volume meter and connect it.
                meter = createAudioMeter(audioContext);
                source.connect(meter);

                // kick off the visual updating
                draw()

                var recordingSign = document.querySelector(".Sign");
                if (recordingSign) {
                    recordingSign.remove();
                }

                var recordingSign = document.createElement('em');
                recordingSign.classList.add("Sign");
                recordingSign.innerHTML = "Recording Has Started";
                recordingSign.style.color = "red";
                var buttonDiv = document.querySelector("#sign");
                buttonDiv.appendChild(recordingSign);
            }
        })
        .catch(function (err) {
            console.log('getUserMedia error: ' + err.name, err);
        });

    //to visualize the volume of stream in canvas
    function draw() {
        WIDTH = canvas.width;
        HEIGHT = canvas.height;

        // clear the background
        canvasContext.clearRect(0, 0, WIDTH, HEIGHT);

        // check if we're currently clipping
        if (meter.checkClipping())
            canvasContext.fillStyle = "red";
        else
            canvasContext.fillStyle = "green";

        // draw a bar based on the current volume
        canvasContext.fillRect(0, 0, meter.volume * WIDTH * 1.4, HEIGHT);

        // set up the next visual callback
        rafID = window.requestAnimationFrame(draw);

    }

    window.onresize = function () {
        canvas.width = mainSection.offsetWidth;
    }

    window.onresize();
*/
})
