const action = $('#action_specific_js').attr('class');

import { ldc_users } from '../users';

function find_work(){
  if(action == 'users_init_show'){
    ldc_users.init_show();
    // ldc_collection.init();
  }
  else{
    setTimeout( find_work, 500 );
  }
}
find_work();
