import { set_urls } from './aws_helper'
import { get_audio_buffer_info_for_waveform } from '../audio/buffer'
import { update_segments } from './segments_helper'
import { active_docid } from './stores'
import Main from '../class_defs/simple_transcription/main.svelte'
function init(ns, obj, short){
  if(!window.ldc.resources.urls) window.ldc.resources.urls = window.ldc.resources.manifest.urls;
  // keys can be 24 or 28?
  if(obj.source.uid.match(/^\w{24,28}$/)){
    // alert(Object.keys(window.ldc.resources.urls))
    if(obj.filename == obj.source.uid) obj.filename = `filename_for_${obj.source.uid}`;
    active_docid.update( () => obj.filename );
    window.ldc.resources.urls[obj.filename] = window.ldc.resources.urls[obj.source.uid];
    window.ldc.resources.original_s3_key = obj.source.uid;
    console.log(JSON.stringify(window.ldc.resources))
    delete window.ldc.resources.urls[obj.source.uid];
  }
  else{
    active_docid.update( () => obj.source.uid );
  }
  // ns.value.docid = obj.source.uid;
  // ns.waveform = new Waveform(ns);
  // full_ep: m.system_ep.system_ep_full
  ns.task_id = obj.task_id;
  window.ldc.ns = ns;
  // const k = Object.keys(window.ldc.resources.urls)[0];
  // let p = set_urls(k);//.then(function(o) {
    // ns.p = p;
    // const url = o.wav;
    // ns.transcript = o.transcript;
    // alert(url)
    const h = {
      // waveform: ns.waveform,
      data_set_id: obj.data_set_id,
      kit_id: obj.kit_id,
      source_uid: obj.source.uid
      // urlp: p
    };
    ns.main = new Main({
      target: $('.view')[0],
      props: h
    });
    window.ldc.main = ns.main;
    ns.waveform.component = ns.main;
    ns.segments = ns.main;
    // active_docid.subscribe( (x) => {
    //   ns.waveform.docid = x;
    //   if(ns.waveform.docid.match(/_A\.wav/)) ns.waveform.docid2 = ns.waveform.docid.replace(/_A/g, '_B');
    //   // ns.set_sources('00', ns.waveform.docid);
    //   // if (ns.waveform.docid.match(/_A\.wav/)) {
    //   //   ns.set_sources('01', ns.waveform.docid2);
    //   // }
    // } );
    // data.waveform = @waveform
    ns.waveform.init();
    update_segments();

    // if(short) return;
    // return get_audio_buffer_info_for_waveform(url, ns.waveform);
  // });

  ns.delete_section = (id) => {
    if (id) {
      if (id === 'all') {
        $('.SectionListItem').each(function(i, x) {
          var iid;
          iid = $(x).data().meta.id;
          return ldc_annotate.add_message(iid, 'delete', null);
        });
      } else {
        ldc_annotate.add_message(id, 'delete', null);
      }
      ldc_annotate.submit_form();
      ldc_annotate.add_callback( () => update_segments() );
    }
  };

  



    // $('.Root').on 'change', '.transcript-input', ->
    //     # iid = $(this).closest(".segment").data().iid
    //     # Somehow jQuery's data() object is corrupted (wrong iid when new segment inserted before another one)
    //     iid = $(this).closest(".segment")[0].attributes['data-iid'].value
    //     iid = $("#node-#{iid} .Transcription").data().meta.id
    //     value = $(this).val()
    //     ldc_annotate.add_message iid, 'change', { value: value }
    //     ldc_annotate.submit_form()

    ns.set_section = () => {
      return this.section.set_section();
    };

    
    ns.add_timestamps2 = (data) => {
      const round_to_3_places = (num) => Math.round(num * 1000) / 1000;
      console.log('check')
      console.log(round_to_3_places)
      var j, len, span, w, x;
      w = this;
      for (j = 0, len = data.length; j < len; j++) {
        x = data[j];
        span = {
          offset: x.beg,
          length: round_to_3_places(x.end - x.beg),
          transcript: x.text,
          speaker: x.speaker
        };
        console.log(span);
        console.log('wave')
        console.log(ns.waveform)
        ns.add_audio_to_list(span);
      }
      ldc_annotate.submit_form();
      ldc_annotate.add_callback( () => update_segments() );
    };

    ns.add_audio_to_list = (span) => {
      return window.sources_object.add_audio_to_list(ns.waveform.docid, '.SegmentList', 'new.Segment', span);
    };

    // return p;
}


export { init }
