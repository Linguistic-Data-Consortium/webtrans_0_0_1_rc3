import { patchp } from "./getp";
function patch(k, v){
}
function make_patch(url, error, success){
  return (k, v) => {
    let x = {};
    x[k] = v;
    patchp( url, x ).then(
      function(data){
        if(data.error) error(data.error.join(' '));
        else           success("updated " + k + " to " + (data[k]), data[k]);
      }
    );
  };
}
export { make_patch }
