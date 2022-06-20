// Generated by CoffeeScript 2.6.1
  // This file defines the interaction with a waveform display.  Most of the
  // underlying audio functionality is handled in ldc_source, so this file is
  // primarily about drawing the display and handling mouse and keyboard events.

// Audio manipulation for playback and for waveform drawing are totally decoupled
  // due to the nature of web programming and what interfaces are available.
  // Playback uses the streaming functionality that browsers provide, and should be
  // as efficient as possible, unencumbered by drawing.  The same should be true
  // of graphical elements other than the waveform, for example the play head which
  // shows the current time of playback.  On the other hand, drawing the waveform
  // should be faster than real time, but the remote location of the data is a
  // complicating factor.  A further complication is the apparent lack of support
  // for retrieving media subparts (other than a stream).  In other words, you
  // can make a range request on a wave file, but it won't have a proper header,
  // so the browser won't decode it.  The solution taken here, mostly implemented
  // in ldc_source, is to retrieve the original header, then retrieve just the
  // chunk of data needed to draw the visible portion of the waveform, and then
  // combine these elements to decode the audio with WebAudio.  Chunks are cached
  // to speed up drawing the same regions in the future.

// Two spans of audio are central to the implementation:  the wave_display, which
  // is the visible region, and wave_selection, which has been selected by the user
  // and is highlighted in red.  The cursor is the vertical red line that shows the
  // mouse position on the waveform, and the play head is the vertical green line
  // that shows the playback position.

// Drawing is actually handled via a requestAnimationFrame loop that is always
  // running.  Operations that affect display simply set certain flags to true,
  // and the next iteration of the loop will call the drawing functions.
import {
  Waveform
} from './waveform/waveform';

window.ldc_waveform = (function() {
  return {
    // create is like a constructor, creating a waveform object with default
    // values for attributes and functions/methods.  It does very little besides
    // returning an object.  Calling init on that object is also like a constructor
    // doing more significant setup work.  Using a ruby analogy, create is like 
    // new and init is like initialize, but init has to be called explicitly.
    create: function(node) {
      return new Waveform(node);
    }
  };
})();

if (!window.ldc) {
  window.ldc = {};
}

if (!window.ldc.vars) {
  window.ldc.vars = {};
}

window.ldc.waveform = window.ldc_waveform;
