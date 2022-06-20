function loop_init(){
  if(!window.ldc) window.ldc = {};
  if(!window.ldc.vars) window.ldc.vars = {};
  if(window.ldc.vars.loop){
    return;
  }
  else{
    const callbacks = new Map();
    window.ldc.vars.loop = callbacks;
    let f = window.requestAnimationFrame || window.webkitRequestAnimationFrame;
    if(!f) f = (callback) => window.setTimeout(callback, 1000 / 60);
    window.requestAnimationFrame = f;
    function audio_loop(t){
      for(let [k, v] of callbacks){ v(t); }
      requestAnimationFrame(audio_loop);
    }
    requestAnimationFrame(audio_loop);
  }
}

export { loop_init }
