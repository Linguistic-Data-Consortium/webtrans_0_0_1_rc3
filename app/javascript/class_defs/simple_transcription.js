import { init } from '../waveform/init'
import { setup } from '../settings'
// import 

class SimpleTranscription {
  constructor(namespace) {
    this.namespace = namespace;
    this.meta = {
      id: '00'
    };
    // this.value = {
    //   docid: null
    // };
    this.index = new Map();
    this.index2 = new Map();
    this.index3 = new Map();
  }

};

const cd = new SimpleTranscription('SimpleTranscription');

ldc_nodes.namespace = function() {
  setup();
  init(cd, $('.Root').data().obj, false);
  const interval = setInterval(function() {
    if(cd.waveform && cd.waveform.duration){
      const oo = {
        kit_uid: $(".Root").data().obj._id,
        duration: cd.waveform.duration
      };
      ldc_nodes.postp('/duration', oo).then(function(x) {
        console.log('xx');
        console.log(x);
      });
      clearInterval(interval);
    }
  }, 1000);

  // .then( () => {
  //   const s = localStorage.getItem('script')
  //   if(s){
  //     if(s.match(/local/)){
  //       console.log("SCRIPT")
  //       cd.waveform.set_times_then_draw(0, 3);
  //     }
  //   }
  // });
};
