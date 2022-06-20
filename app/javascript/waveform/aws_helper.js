// aws helper for transcription related urls
// pulls in generic helper functions
import { getSignedUrlPromise, s3url } from '../work/aws_helper'
import { getp } from '../work/getp'
import { active_docid } from '../waveform/stores'

function signed_url_for_audio(bucket, key, urls, k) {
  return getSignedUrlPromise(bucket, key)
  .then(function(data){
    urls[k] = data;
  })
  .then(function(){
    if(k.match(/_A.wav$/)) {
      bucket = window.ldc.resources.bucket.replace(/_A/, '_B');
      key = k.replace(/_A/g, '_B');
      getSignedUrlPromise(bucket, key)
        .then(function(data) {
          urls[k.replace(/_A/g, '_B')] = data;
        });
    }
  })
  .then( () => { return { wav: k, wav_url: urls[k] } } );
}

function set_urls(k){
  const found = s3url(k);
  if(found.bucket) {
    return set_urls3(found, k);
    // .then( (x) => signed_url_for_audio(found.bucket, found.key, urls, x) )
    // .then( () => k );
  }
  else{
    return set_urls2(k);
  }
}

function set_urls3(found, k){
  window.ldc.resources.bucket = found.bucket;
  const urls = window.ldc.resources.urls;
  return Promise.resolve( 
    k.match(/wav$/) ? signed_url_for_audio(found.bucket, found.key, urls, k) :
      getSignedUrlPromise(found.bucket, found.key)
      .then( getp )
      .then(function(d){

        const o = {};

        // resolve this one in parallel
        if(d.tdf){
          let found = s3url(d.tdf);
          o.transcript = getSignedUrlPromise(found.bucket, found.key)
          .then( getp )
          .then(function(d){
            return {
              use_transcript: 'tdf',
              found_transcript: d
            };
          });
        }

        // resolve this one in parallel
        if(d.sad_with_aws){
          let found = s3url(d.sad_with_aws);
          o.transcript = getSignedUrlPromise(found.bucket, found.key)
          .then( getp )
          .then(function(d){
            return {
              use_transcript: 'sad_with_aws',
              found_transcript: d
            };
          });
        }

        if(d.wav){
          active_docid.update( () => d.wav );
          found = s3url(d.wav);
          return signed_url_for_audio(found.bucket, found.key, urls, d.wav)
            .then( (x) => {
              o.wav = x.wav;
              o.wav_url = urls[x.wav];
              return o;
            });
        }
        else{
          return o;
        }
        
      })
      .catch( () => alert('error, try refreshing') )
  );
}

function set_urls2(k){
  const urls = window.ldc.resources.urls;
  if(k.match(/^http/)) urls[k] = k;
  if(urls[k].substr(0, 2) === 's3'){
    if(urls[k] === 's3'){
      return alert('missing bucket');
    }
    else{
      window.ldc.resources.bucket = urls[k].replace(/^s3(:\/\/)?/, '').replace(/\/.+/, '');
      const bucket = window.ldc.resources.bucket;
      let key = k.replace(bucket + '/', '').replace('filename_for_', '');
      if(window.ldc.resources.original_s3_key) key = window.ldc.resources.original_s3_key;
      return signed_url_for_audio(bucket, key, urls, k);
      // .then( () => k );
    }
  }
  else{
    return Promise.resolve( { wav: k, wav_url: urls[k] } );
  }
}

export { set_urls }
