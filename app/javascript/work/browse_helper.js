import { getp } from "./getp";
function get_open_tasks(x, open_tasks){
  let browse_tasks = [];
  console.log('open')
  console.log(x)
  for(let y of x[0]){
    if(y.free){
      browse_tasks.push(getp("/browser?blobs=audio&task_id=" + y.task_id));
      // work_paths[y.task_id] = y.work_path;
      open_tasks[y.task_id] = y;
      open_tasks[y.task_id].has_kit = y.state == 'has_kit' ? y.kit_uid : false;
    }
  }
  return Promise.all(browse_tasks).then( (a) => {
    let b = [];
    for(let x of a){
      for(let y of x){
        if(y.source_id){
          y.type = 'file';
          y.uid = y.key;
        }
        else{
          y.type = 'kit';
        }
      }
      b = b.concat(x);
    }
    return b;
  });
}
export { get_open_tasks }
