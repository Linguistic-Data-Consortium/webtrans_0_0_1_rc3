<script>
    import { createEventDispatcher } from 'svelte'
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte'
    let help;
    onMount( () => {
        // keyboard.root_hide();
        help.focus();
    } );
    let keys = {
        h: "main"
    }
    function keydown(e){
        if(Object.keys(keys).includes(e.key))
            dispatch('show', keys[e.key]);
        else
            dispatch('show', null);
    }
</script>

<style>
</style>

<div bind:this={help} tabindex=0 on:keydown={keydown} class="p-4 h-96 overflow-auto">
    <div>Hit <b>h</b> to return to the main menu.</div>
    <div>
        <div class="text-xl my-4">Overview</div>
        <p>
The mouse moves the <b>cursor</b>, a vertical red line, on the waveform.
Dragging the mouse on the waveform sets the <b>selection</b>, shown as a red
rectangle on the waveform.  There is also a red rectangle below the waveform,
the <b>scrollbar</b>.  The scrollbar area represents the full length of the 
audio file, with the size and position of the scrollbar representing the portion
of the audio displayed in the waveform.  Clicking on this area will navigate
within the audio file. The <b>active
segment</b> is the segment associated with the text input and the waveform
selection.  The text of the segment becomes red when active.  Clicking on an
underline under the waveform activates and plays that segment.  Clicking on
a line in the transcript activates a text box for typing.
        </p>
    </div>
    <div>
        <div class="text-xl my-4">Keystrokes</div>
        <p>
The <b>cursor</b> and <b>selection</b> can also
be controlled with the keyboard.  In fact, all functions that can be performed with the mouse can also be performed with the keyboard.  The eight <b>home keys</b> <i>asdf jkl;</i> can be used for various moving operations.
The left hand keys move backwards, and the right hand keys move forwards, with
the inner keys being smaller increments of movement, and the outer keys being
larger increments.  In a browser window, the <b>focused element</b> is the element that receives keystrokes.
For example, <i>for typed characters to appear in a text box, that text box must have
focus</i>.  Since focusing the waveform itself would be problematic, the keyboard icon 
<i class="fa fa-keyboard"/> in the upper right of the display is used as a proxy.  When the keyboard icon is focused, the icon will be green, and green will surround the waveform.  Most keyboard operations require this kind of focus.  Clicking on the waveform will return focus to the keyboard icon, as will clicking on the icon itself, since clicking on the waveform is sometimes undesirable because it removes the selection.
        </p>
    </div>
    <div>
        <div class="text-xl my-4">Waveform Modes</div>
        <ol>
The <b>mode</b> is indicated next to the keyboard icon in the upper right of the display.
<ol>
<li>
- <b>cursor mode</b> The home keys move the cursor; the tools starts in this mode.
</li>
<li>
- <b>window mode</b> The home keys will move the visible window of the waveform.
</li>
<li>
- <b>beg mode</b> / <b>end mode</b> The home keys will move the begin / end of a selection, if there is one; same as dragging a selection boundary.
</li>
        </ol>
    </div>
    <div>
        <div class="text-xl my-4">Other Operations</div>
        <div class="other">
    <ol>
<li>
- <b>tab</b> puts focus on the text input box
</li>
<li>
- <b>space</b> play/stop.  plays selection if there is one.
</li>
<li>
- <b>c/w/b/e</b> change mode to cursor/window/beg/end
</li>
<li>
- <b>i/o</b> zoom in/out
</li>
<li>
- <b>z</b> alternately zoom in and out
</li>
<li>
- <b>enter</b> create segment from selection
</li>
<li>
- <b>forward slash</b> create segment from last segment to play head
</li>
<li>
- <b>m</b> merge active segment with the following segment
</li>
<li>
- <b>,</b> split active segment at the cursor
</li>
<li>
- <b>p</b> playback menu
</li>
    </ol>

        </div>
    </div>
</div>
