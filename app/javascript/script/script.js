const m = new Map();
m.set('show', 1);
m.set('record', 1);
function check_line_of_code(x){
    if(x.length == 0) return true;
    // if(m.has(x)) return true;
    let m;
    if(m = x.match(/^\s*(show)\s*$/)){
      console.log(m);
      return { command: 'show' }
    }
    if(m = x.match(/^\s*(kit)\s*(\w+)\s*$/)){
      console.log(m);
      return { command: 'kit', uid: m[2] }
    }
    else if(m = x.match(/\s*record\s*/)){
      
    }
    else{
      
    }
    return false;
}

export { check_line_of_code }
