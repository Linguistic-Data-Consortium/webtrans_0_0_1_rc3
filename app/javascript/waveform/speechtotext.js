import { StartTranscriptionJobCommand, GetTranscriptionJobCommand } from "@aws-sdk/client-transcribe";
import { getTranscribeClient } from '../work/aws_helper'
// import { getp } from '../work/getp'

// import css from './speechtotext.scss';

// Store the kit's transcript in local storage to avoid repeating requests to aws
const LOCALSTORAGE = "speechRecognititionTranscripts";
const ls = {
  get: key=>{
    const o = JSON.parse(window.localStorage.getItem(LOCALSTORAGE));
    if (o===null||!o.hasOwnProperty(key)) return null;
    return o[key];
  },
  set: (key,value)=>{
    let o = JSON.parse(window.localStorage.getItem(LOCALSTORAGE));
    if (o===null) o = {};
    o[key] = value;
    window.localStorage.setItem(LOCALSTORAGE,JSON.stringify(o));
  }
}


async function transcribeFile(uri){
  const jobname = ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g,a=>(a^Math.random()*16>>a/4).toString(16));
  const params = {
    Media: { /* required */
      MediaFileUri: uri
    },
    TranscriptionJobName: jobname, /* required */
    // OutputBucketName: 'ldc-jeremy-test',
    LanguageCode: 'en-US',
    MediaFormat: 'wav'
  };
  try {
    let command = new StartTranscriptionJobCommand(params);
    await getTranscribeClient().send(command);
    command = new GetTranscriptionJobCommand({TranscriptionJobName: jobname});
    const jobresult = await new Promise(async r=>{
      let callback = async()=>{
        const j = await getTranscribeClient().send(command);
        if (j){
          if (j.TranscriptionJob.TranscriptionJobStatus=='COMPLETED')
            return r(j.TranscriptionJob);
          else if (j.TranscriptionJob.TranscriptionJobStatus=='FAILED')
            console.error("Could not automatically extract speech from",uri);
          else
            setTimeout(callback,250);
        }
      };
      await callback();
    });
    // const presigned = await getSignedUrlPromise('ldc-jeremy-test', jobname+'.json');
    // const transcript = await fetch(presigned);
    const transcript = postp('/aws', {url: jobresult.Transcript.TranscriptFileUri});
    return transcript;
  }
  catch (e){
    console.error("Could not automatically extract speech from",uri);
  }
}
const getTranscript = async()=>{
  try {
    const url = $(".Root").data().resources.urls[$(".filename").text()].replace(/\?[^/]+/,'');
    const response = await transcribeFile(url);
    return response.results.items;
  }
  catch (e){
    console.error("Could not retrieve transcript");
    return undefined;
  }
}

// A custom class to make it easier to associate timepoints with intervals
class ArrayOfIntervals extends Array {
  add(pair,value){
    if (!(pair instanceof Array) || isNaN(pair[0]) || isNaN(pair[1]))
      return console.error("Intervals.add must take a pair of numbers as its first argument");
    const min = Math.min(...pair), max = Math.max(...pair);
    const itv = {min: min, max: max, value: value};
    itv.delete = ()=>{
      const i = this.indexOf(ivt);
      if (i>=0) this.splice(i,1);
    }
    this.push(itv);
  }
  get(index){
    if (isNaN(index)) return [];
    const r = [];
    for (let i=0; i < this.length; i++)
      if (this[i].min<=index && this[i].max>=index) r.push(this[i]);
    return r;
  }
}

// When ASR is on, CurrentSR contains the items from aws transcribe 
let CurrentSR = null;

const old_empty_segments = []
// Detect empty/blank segments and fill them with the words from CurrentSR
const fillSegments = async()=>{
  if (CurrentSR===null) return;
  const emptySegments = new ArrayOfIntervals();
  $(".Node.SegmentListItem").each((i,n)=>{
    const data = $(n).data();
    if (data===undefined || data.Segment === undefined || data.Transcription === undefined) return;
    const value = data.Transcription.value.value,
          id = data.Transcription.meta.id,
          beg = data.Segment.value.beg,
          end = data.Segment.value.end;
    if (old_empty_segments.indexOf(id)>0) return;
    if (value===null || (typeof value == "string" && value.length==0))
      emptySegments.add([beg-0.1,end], {id: id, words: []});  // SAD is sometimes too strict, so beg-0.1s
  });
  CurrentSR.forEach( w => 
    emptySegments.get(w.start_time).forEach(s=>s.value.words.push(w.alternatives[0].content)) 
  );
  emptySegments.forEach( s => 
    window.ldc_annotate.add_message(s.value.id, 'change', {value: s.value.words.join(" ")})
  );
  if (emptySegments.length){
    window.ldc_annotate.submit_form();
    ldc_annotate.add_callback( () => window.ldc.main.refresh() );
  }
}

let running = false;
const detect_new_empty_segments = async()=>{
  if (CurrentSR===null||running) return;
  running = true;
  const emptySegments = $(".Transcription").filter((i,e)=>
    $(e).data("value").value==''||$(e).data("value").value===null
  );
  if (emptySegments.length){
    const new_empty_segments = emptySegments
                                .map( (i,e) => $(e).data("meta").id )
                                .filter( (i,id) => old_empty_segments.indexOf(id)<0 );
    if (new_empty_segments.length && confirm("New empty segments detected. Do you want to apply automatic speech recognition?"))
      await fillSegments();
    new_empty_segments.each( (i,id)=> old_empty_segments.push(id) );
  }
  running = false;
  window.requestAnimationFrame(detect_new_empty_segments);
}


// Simple class to expose activate/deactivate
class SpeechRecognition {
  static async activate(){
    const obj = $('.Root').data('obj');
    if (!obj || !obj.hasOwnProperty("_id"))
      return console.error("No kit id found in Root obj");
    CurrentSR = ls.get(obj._id);
    if (CurrentSR===null){
      let notification = $(".speechrecognition");
      if (notification.length) notification.text("Generating automatic transcripts...");
      CurrentSR = await getTranscript();
      ls.set(obj._id,CurrentSR);
      if ($(".speechrecognition").length==0) notification = $("<div class='speechrecognition'>");
      $('.ChannelA').before(notification.text("Automatic Speech Recognition: ON"));
      setTimeout(()=>notification.remove() , 1500);
    }
    fillSegments();
    setTimeout(detect_new_empty_segments, 1000); // Start with 1s delay to give time to fill existing segments
  }
  static async deactivate(){ CurrentSR=null; }
}

export { SpeechRecognition }
