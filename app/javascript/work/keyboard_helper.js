function fmap_helper(mode, delegate, e, map){
  if(e.ctrlKey || e.altKey) map = map.control;
  if(mode){
    map = map[delegate.mode];
  }
  else{
    if(!map) map = {};
  }
  if(map){
    const f = map[e.key];
    if(f){
      return f;
    }
    else{
      console.log('no binding');
      console.log(e);
    }
  }
  else{
    console.log(`mode not found: ${delegate.mode}`);
    console.log(e);
  }
}

function fmap2(mode, delegate, e, map){
  if(e.ctrlKey || e.altKey) map = map.control;
  if(mode){
    map = map[delegate.mode];
  }
  else{
    if(!map) map = {};
  }
  if(map){
    const f = map[e.key];
    if(f){
      if(delegate[f]){
        return delegate[f](e);
      }
      else{
        console.log(`no function: ${f}`);
      }
      // return f;
    }
    else{
      console.log('no binding');
      console.log(e);
      return 'none';
    }
  }
  else{
    console.log(`mode not found: ${delegate.mode}`);
    console.log(e);
  }
}

function find_node_id(iid, name){
    const ee = document.getElementById(`node-${iid}`)
    for(let i = 0; i < ee.children.length; i++){
        if(ee.children[i].className.split(' ')[0] == name) return ee.children[i].id.split('-')[1];
    }
}

export { fmap_helper, fmap2, find_node_id }
