import { x } from '../work/run'

function find_run(){
  if(
    window.ldc_run && window.ldc_run_run
  ){
    window.ldc_run.run(window.ldc_run_run);
  }
  else{
    setTimeout( find_run, 500 );
  }
}
find_run();
