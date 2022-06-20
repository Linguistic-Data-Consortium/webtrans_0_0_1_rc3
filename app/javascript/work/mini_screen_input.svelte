<script>
    let invisible = true;
    let title = 'TITLE';
    let input;
    let keyboard;
    export function open(h){
        invisible = false;
        title = h.title;
        keyboard = h.keyboard;
        // remove = h.remove;
        setTimeout(function(){
            // document.getElementById('set_new_speaker_input').focus()
            input.focus()
        }, 100);
    }
    export function close(){
        invisible = true;
        // document.getElementById('set_new_speaker_input').value = '';
        value = '';
    }
    export function keydown(e){
        keyboard.handle(e, true);
    }

    let value = '';
    export function open_helper(h){
      const kb = h.keyboard;
      kb.map = { Enter: 'setf', Escape: 'escape' };
      kb.delegate.setf = function() {
        // id =  $('.crnt .Speaker').data().meta.id
        h.setf(value);
        kb.reset();
        close();
      };
      kb.delegate.escape = function() {
        // id =  $('.crnt .Speaker').data().meta.id
        kb.reset();
        close();
      };
      open(h);
    }
</script>

<style>
</style>

<div class="shadow-xl bg-white border-2 rounded fixed right-24 top-48 opacity-100 z-10" class:invisible tabindex=0>
    <div class="p-2">
        <div class="p-1 text-sm">{title}</div>
        <input bind:this={input} id="set_new_speaker_input" class="pl-1" on:keydown={keydown} bind:value={value} >
        <div class="p-1 text-sm">or ESC to exit</div>
    </div>
</div>
