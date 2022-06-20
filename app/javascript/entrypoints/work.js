import { x } from '../work/work'

const action = $('#action_specific_js').attr('class');

function find_work(){
  if(
    window.ldc_work && window.ldc_work_work &&
                        window.ldc_work_manifest &&
    window.ldc_annotate && window.ldc_annotate_initt
  ){
    window.ldc_work.work(window.ldc_work_work);
    window.ldc_work.manifest(window.ldc_work_manifest);
    window.ldc_annotate.initt(window.ldc_annotate_initt)
  }
  else{
    setTimeout( find_work, 500 );
  }
}
find_work();
