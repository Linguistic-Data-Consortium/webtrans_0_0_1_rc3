<script>
    import { getp, postp, deletep, patchp } from "./getp";
    import { StartTranscriptionJobCommand, GetTranscriptionJobCommand } from "@aws-sdk/client-transcribe";
    import { getSignedUrlPromise, getTranscribeClient } from './aws_helper'
    export let url;
    const run = async (params) => {
      try {
        const data = await getTranscribeClient().send(new StartTranscriptionJobCommand(params));
        console.log("Success - put", data);
      } catch (err) {
        // console.log("Error", err);
        console.log(JSON.stringify(err))
      }
    };
    let tp;
    const run2 = async (params) => {
      try {
        const data = await getTranscribeClient().send(new GetTranscriptionJobCommand(params));
        // console.log("Success - put", data);
        let u = data.TranscriptionJob.Transcript.TranscriptFileUri;
        console.log(u);
        // tp = getp(u);
        tp = postp('/aws', { url: u });
      } catch (err) {
        console.log("Error", err);
        // console.log(JSON.stringify(err))
      }
    };
    let first = true;
    function get(){
        // getSignedUrlPromise('coghealth', url).then( (url2) => {
            // let url2 = "https://coghealth.s3.amazonaws.com/demo/CarrieFisher10s.wav";

            const params = {
              TranscriptionJobName: "JOBNAME4",
              LanguageCode: "en-US", // For example, 'en-US'
              MediaFormat: "wav", // For example, 'wav'
              Media: {
                MediaFileUri: url
                // For example, "https://transcribe-demo.s3-REGION.amazonaws.com/hello_world.wav"
              },
              // OutputBucketName: 'coghealth'
            };
            // if(first){
                run(params);
                // first = false;
            // }
            // else{
                setTimeout( () => {
                    run2({TranscriptionJobName:"JOBNAME3"});
                }, 1000 );
            // }
        // });
    }
    get();
</script>

{#if tp}
    {#await tp}
        loading...
    {:then value}
        <pre>
            {JSON.stringify(value, null, 2)}
        </pre>
    {/await}
{/if}
