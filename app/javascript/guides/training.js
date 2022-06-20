console.log("Hello from training.js");

import { Guide } from "./guide";
const isTaskPage = () => Guide.route(["task_users", "get"]) && Guide.route("workflow_id")
let is_playing=()=>false; // to be defined later
const xpath = sel=>document.evaluate(sel,document,null,XPathResult.FIRST_ORDERED_NODE_TYPE,null).singleNodeValue;

/**
 * GUIDE CREATION
 */
const tuto = new Guide("Webtrans Tutorial");

/** 
 * Helper functions 
 */
const deleteNodesAfter = after => {
  // if ($(".ChannelA").length<1) return;
  const channel = document.querySelector(".ChannelA");
  let anyDeletion = false;
  // $(".Node").each((i,n)=>{
  document.querySelectorAll(".Node").forEach(n=>{
    const data = $(n).data("meta");
    if (data === undefined) return;
    const id = Number(data.id);
    if (isNaN(id) || id < 4 || id <= after) return;
    window.ldc_annotate.add_message(id, 'delete', null);
    anyDeletion = true;
  });
  if (anyDeletion){
    window.ldc_annotate.submit_form();
    // window.ldc_annotate.add_callback( () => window.ldc.main.refresh() );
  }
}
const appear = (...args) => tuto.wait(...args), disappear = s => appear(s, true);
const promise = f => tuto.promise(f);
let gobackDialogBox = null;
const step = (t, f) => tuto.step(t, async () => {
  if (!isTaskPage()) throw "Abort";
  let misc = {};
  try {
    const incoming = JSON.parse(tuto._misc);
    if (incoming && incoming instanceof Object)
      misc = Guide.extend(incoming, misc);
  }
  catch { }
  if (!(misc.lastNodes instanceof Array))
    misc.lastNodes = [];
  const oldMax = misc.lastNodes[tuto._currentStep];
  let max = 3;
  // $(".Node").each((i,v)=>max = Math.max(max,$(v).data('meta').id))  
  document.querySelectorAll(".Node").forEach(v=>max = Math.max(max,$(v).data('meta').id));
  if (oldMax!==null && !isNaN(oldMax) && oldMax < max){
    gobackDialogBox = document.createElement("DIV");
    gobackDialogBox.classList.add("gobackDialogBox");
    document.body.append(gobackDialogBox);
    // gobackDialogBox = $("<div>").addClass('gobackDialogBox').appendTo($("body"))
    gobackDialogBox.innerText = "Do you want to erase the modifications you have made\
                          between the step you are coming from\
                          and the one you are jumping to?"; // ).appendTo($("body"));
    await new Promise(r=>gobackDialogBox.dialog({
      title: "Erase progress?",
      resizable: false,
      width: 350,
      closeOnEscape: false,
      modal: true,
      buttons: {
        Erase: () => {
          deleteNodesAfter(oldMax);
          // Erase next steps' states
          for (let i = tuto._steps.length-1; i > tuto._currentStep; i--)
            misc.lastNodes[i] = null;
          gobackDialogBox.dialog( "close" );
        },
        No: () => gobackDialogBox.dialog( "close" )
      },
      beforeClose: r
    }));
  }
  misc.lastNodes[tuto._currentStep] = max;
  tuto._misc = JSON.stringify(misc);
  await f();
});

/**
 * STEPS
 */
const welcome = step("Welcome", async () => {
  await openDialog(
    "Welcome to the Webtrans Tutorial!",
    "Hi! This tutorial will guide you through how to use the transcription tool.\
     This tool allows you to work remotely for the LDC, and it was especially designed to help you transcribe\
     quickly and easily."
  );

  const bottomBar = await appear(".guide.bottomBar");
  await bottomBar.tte("<p>See the bar at the bottom of the page?</p>\
       <p> This tutorial is composed of <em>steps</em>. In case you miss a step, \
       you can use the dropdown menu in this bottom bar to navigate back to it.\
       Click <em>Reset</em> to go back to the first step with a blank slate (all progress will be lost).</p>", "above", "cover").promise;
  introducing_waveform();
});

/**
 * @description Introducing the Waveform window and It's features
 */
const introducing_waveform = step("Introduction & Playback", async function () {
  await openDialog(
    "Introduction",
    "Let us start with the basics of the interface and see how to play our file"
  );

  const waveform = await appear(".node-waveform");
  await waveform.tte("<p>This represents the waveform of an audio file.</p>", "cover", { click: true }).promise;
  
  const ticks = await appear(".waveform-ticks");
  await ticks.tte("<p>This timeline (in seconds) helps you locate yourself as you navigate through the waveform.</p>", "cover", {click: true}).promise;
  
  const filename = await appear(".filename");
  await filename.tte("<p>The name of the audio file you are transcribing appears here to the left.</p>", "cover", "below", "left", {click: true}).promise;
  await waveform.tte("<p>To play the audio file, start by clicking anywhere in the waveform window\
                   (you should see a red cursor as you move your mouse).</p>", "cover", {
    click: false,
    promise: r=>waveform.addEventListener('click',r)
  }).promise;
  await waveform.tte("<p>Now press the space bar on your keyboard to play the audio.</p>", {
    click: false,
    promise: r=>{
      const play_callback = ()=>{
        if (is_playing()) r();
        else window.requestAnimationFrame(play_callback);
      };
      play_callback();
    },
    // condition: ()=>$(".keyboard:focus").length>0,
    condition: ()=>document.querySelector(".keyboard:focus"),
    loseCondition: async ()=>{
      const channel = await appear(".ChannelA");
      await channel.tte("<p>Oops, it looks like you clicked outside the waveform window.</p>\
                    <p>Please click inside the waveform window again.</p>", {
        click: false,
        cover: true,
        promise: r=>channel.addEventListener('click',r)
      }).promise;
      // $(waveform.tooltips[0]).find("p").text("Great, now press the space bar to play the audio");
    }
  }).promise;
  await waveform.tte("<p>Great! You can press Space again to stop playing, or wait until playback is over.</p>", {
    click: false,
    promise: r=>{
      const stop_callback = ()=>{
        if (!is_playing()) r();
        else window.requestAnimationFrame(stop_callback);
      };
      stop_callback();
    }
  }).promise;
  // Wait 500ms to prevent a keyup on spacebar from closing first dialog from next step
  await promise(r => setTimeout(r, 500));

  navigating_waveform();
});

/**
 *  @description Teching users how to Move Back and Fro in the Waveform Window
 */
const navigating_waveform = step("Navigating the waveform", async function () {
  await openDialog(
    "Navigating the waveform",
    "Most audio files are long enough that their waveform does not entirely fit at once in the window.\
     In this step, you will learn how to navigate the waveform using your mouse (we will later see how to do it using your keyboard)."
  );

  const waveform_scrollbar = await appear(".waveform-scrollbar");
  await waveform_scrollbar.tte("<p>This area can be used to scroll the waveform window. Try clicking and dragging \
                                   the scrollbar to the right to see the remaining of the audio.</p>\
                                <p>Note that the longer the audio file, the narrower the red bar in this area appears.</p>",
    {
      cover: true,
      click: false,
      promise: r => {
        let x = NaN, moved = false;
        waveform_scrollbar.addEventListener('mousedown', e => x = e.clientX);
        // $(document).mousemove(e => {
        //   if (!isNaN(x) && (e.clientX - x) > 20) moved = true;
        // });
        // $(document).mouseup(e => {
        //   if (!isNaN(x) && moved) setTimeout(r, 500);
        // });
        document.addEventListener('mousemove', e => {
          if (!isNaN(x) && (e.clientX - x) > 20) moved = true;
        });
        document.addEventListener('mouseup', e => {
          if (!isNaN(x) && moved) setTimeout(r, 500);
        });
      }
    }
  ).promise;

  const waveform = await appear(".node-waveform");
  await waveform.tte("<p>Great! Note that rendering the waveform takes time, so it might get updated only after you release the click.\
                         Feel free to practice more before moving on to the next step.</p>", { click: true }).promise;

  makeAselection();
});

/**
 * @description How to Creating the Audio Segments/Chunks
 */
const makeAselection = step("Create an Audio Segment", async function () {
  const waveform = await appear(".node-waveform");
  await openDialog(
    "Create an Audio Segment",
    "Transcribing the full audio file as one long single line would be unwise. In this step, \
       we will learn how to create short <em>segments</em> that can easily be transcribed.<br>\
       Ideally, segments should only be a few words long, and no longer than a single sentence."
  );
  await waveform.tte("<p>To start with, let's see how to make a selection: move your cursor over the waveform, click, drag your cursor, and release.</p>\
               <p>Important tip: when transribing don't try to create segements longer than 8 seconds.<br>\
                  For now, just create a short segment, just 2s long for example.</p>", "cover", {
    click: false,
    promise:r=>selectionHappened(r)
  }).promise;

  let pressedEnter = false;
  await waveform.tte("<p>Great job! You can press the space bar to listen to the selection.</p>", {
    // key: " ",
    click: false,
    // promise:r=>$(".keyboard, .Root").keydown(e=>{
    promise:r=>document.querySelectorAll(".keyboard, .Root").forEach(n=>n.addEventListener('keydown', e=>{
      if (e.key==" " || e.key=="Enter") {
        if (e.key=="Enter") pressedEnter = true;
        r.solved=true;
        r();
      }
      else if (r.solved===undefined) {
        e.stopPropagation();
        e.preventDefault();
        // $(waveform.tooltips[0]).find("p").text("Oops, wrong key. Press the space bar to listen to the selection");
        waveform.tooltips[0].childNodes.forEach(n=>{
          if (n.nodeName=="P") n.innerText = "Oops, wrong key. Press the space bar to listen to the selection";
        });
        return false;
      }
    })) ,
    // condition:()=>$("rect.selection").width()>5&&$(".keyboard:focus").length>0,
    condition: ()=> document.querySelector(".keyboard:focus") && 
                  parseInt(window.getComputedStyle(document.querySelector("rect.selection")).width)>5
    ,
    loseCondition: async()=>{
      await promise(r=>setTimeout(r,100));
      await getSelectionAndFocusBack();
      // $(waveform.tooltips[0]).find("p").text("Press the space bar to listen to the selection");
      waveform.tooltips[0].querySelector("p").innerText = "Press the space bar to listen to the selection";
    }
  }).promise;
  // This will not run if the user pressed Enter instead of Space in response to the previous tooltip
  if (!pressedEnter){
    await checkIfAudioFinishedPlaying();
    await waveform.tte("<p>Now press <tt>Enter</tt> to create a new segment for this selection.</p>", {
      click: false,
      key: "Enter",
      // condition: ()=>$("rect.selection").width()>5&&$(".keyboard:focus").is(":visible"),
      condition: ()=>{
        const rect = document.querySelector("rect.selection");
        return rect && parseInt(window.getComputedStyle(rect).width)>5 && document.querySelector(".keyboard:focus");
      },
      loseCondition: async()=>{
        await promise(r=>setTimeout(r,100));
        await getSelectionAndFocusBack();
        waveform.tooltips[0].childNodes.forEach(n=>{
          if (n.nodeName=="P") n.innerHTML = "<p>Press <tt>Enter</tt> to create a new segment.</p>";
        });
      }
    }).promise;
  }

  const input = await appear(".segment div input");
  let input_parent = input.parentElement.parentElement;
  const n = input_parent.attributes['data-iid'].value;
  await input.tte("<p>This text input box is where you transcribe the newly created segment.</p>\
                   <p>Type some text and then press <tt>Enter</tt> to finish it.</p>\
                   <p>Tip: you can listen to the segment again by pressing <tt>Ctrl</tt>+<tt>Spacebar</tt>.</p>", {
    cover: true,
    y: "above",
    click: false, 
    key: "Enter",
    // condition:()=>document.querySelector(`.segment-${n} .segment input:focus`),
    condition: ()=>xpath(`//div[@data-iid='${n}']/div/input`),
    loseCondition:async ()=>{
      // const segment_middle_cell = await appear(`.segment-${n} .d-table-cell:nth-child(2)`);
      const segment_middle_cell = await appear(`//div[@data-iid='${n}']/div/following-sibling::div`,false,true);
      await segment_middle_cell.tte("<p>You need to keep focus on the input box. Click to bring back focus.</p>",{
        click: false,
        cover: true,
        y: 'above',
        promise: r=>segment_middle_cell.addEventListener('click', r)
      }).promise;
    }
  }).promise;
  // This one is a little complex: it's very likely that a click would miss the blue bar,
  // so we need to help the user find it back
  await promise(r => {
    const play_callback = () => {
      if (is_playing()) r();
      else window.requestAnimationFrame(play_callback);
    };
    play_callback();
  });
  
  // const n = parseInt($(".underline_rect:last:visible").attr("class").replace(/^.*underline-rect-(\d+).*$/,"$1"));
  const replay = await appear(".underline-rect-" + (Number(n)+1));
  await replay.tte("<p>Playback starts automatically after you press <tt>Enter</tt>.</p>\
                    <p>Note that segments come with blue bars that help you delineate them.</p>", {
    click: true,
    cover: true
  }).promise;
  //                   <p>You can also use the blue bar to play a segment again. Try clicking the blue bar</p>", {
  //   click: false,
  //   cover: true,
  //   // condition: () => $(".underline-rect-" + (n + 1)).parents('body').length > 0,
  //   condition: () => document.querySelector(".underline-rect-" + (Number(n)+1)),
  //   loseCondition: async () => await lostBlueBar(replay, n),
  //   promise: async r => {
  //     // await promise(r2 => $(".node-waveform").click(".underline-rect-" + (n + 1), r2));
  //     await promise(r2 => document.querySelector(".underline-rect-" + (Number(n)+1)).addEventListener("click", r2));
  //     const play_callback = () => {
  //       if (is_playing()) r();
  //       else window.requestAnimationFrame(play_callback);
  //     };
  //     play_callback();
  //   }
  // }).promise;

  // await promise(r => {
  //   const stop_callback = () => {
  //     if (!is_playing()) r();
  //     else window.requestAnimationFrame(stop_callback);
  //   };
  //   stop_callback();
  // });

  await promise(r => setTimeout(r, 500));

  await openDialog(
    "Create an Audio Segment",
    "<p>Great Job! Now try creating another 1-2s audio segment not overlapping with the previous one.</p>" +
    "<p>Remember, blue lines indicate audio segments, you can use them as a guide to create non-overlapping segments.</p>"
  );

  await waveform.tte({
    content: "<p>Reminder: click, drag and release, then press <tt>Enter</tt>, type some text and press <tt>Enter</tt> again.</p>",
    cover: false,
    key: false,
    click: false,
    y: "above",
    promise: r => document.addEventListener("keydown", e => { if (e.key == "Enter" && document.querySelector(".segment input:focus")) r(); })
    // promise: r => $(document).on("keydown", ".segment input", e => { if (e.key == "Enter") r(); })
  }).promise;

  await checkIfAudioFinishedPlaying();
  await promise(r => setTimeout(r, 500));

  await openDialog(
    "Create an Audio Segment",
    "Good Job! You just created, transcribed and re-heard a particular segment on your own.\
       Let's move on to next step."
  );

  toggle();
});

/**
 * @description Toggle using Tab and,
 *              Use of Enter button and it's effect in both waveform and input area
 */
const toggle = step("Toggle", async function () {
  const waveform = await appear(".node-waveform");
  await openDialog(
    "Toggle",
    "While working on a segment, the ability to toggle between the waveform window and the text window makes you much more effcient.<br><br>\
       Indeed, you can use keyboard commands from either window, but the two windows use different keys or key combinations.\
       Let us learn how to toggle from one window to the other."
  );

  let segment = await appear("//div[contains(@id,'segment-')]",false,true);
  await segment.tte("<p>First, click on the first transcription line.</p>", {
    click: false,
    cover: true,
    y: "above",
    promise: r => segment.addEventListener('click',r)
  }).promise;

  // const inputCondition = ()=>$(".segment input:focus").is(":visible");
  const inputCondition = ()=>document.querySelector(".segment input:focus");
  const inputLoseCondition = async()=>{
    const segmentMidCol = await appear("//div[contains(@id,'segment-')]/div/following-sibling::div",false,true);
    await segmentMidCol.tte("<p>It looks like you lost focus from the input box. Click here to get it back.</p>",{
      cover: true,
      y: 'above',
      click: false,
      promise: r=>segmentMidCol.addEventListener('click',r)
    }).promise;
    await appear(".segment input");
  };

  let input = await appear(".segment input");
  input.focus();
  await input.tte("<p>The text window currently has focus: notice the red border around the textbox.</p>\
                           <p>Toggle focus by pressing the <tt>Tab</tt> key on your keyboard.</p>", {
    click: false,
    cover: false,
    y: 'above',
    key: "Tab",
    condition: inputCondition,
    loseCondition: inputLoseCondition
  }).promise;

  // Can get back focus
  const keyboard_icon = await appear(".fa-keyboard");
  // $(".keyboard").focus(); // safety measure
  document.querySelector(".keyboard").focus(); // safety measure
  await keyboard_icon.tte("<p>The waveform window now has focus: notice this framed keyboard icon.</p>\
    <p>Press <tt>Tab</tt> again to bring focus back to the text input field.</p>", {
    // <p>Click the text input field below to bring focus back to it</p>", {
    cover: true,
    click: false,
    key: "Tab",
    // promise: r=>$(".segment:first").on("focusin", ".segment input", r),
    // promise: r=>document.addEventListener("focusin", e=>{if(document.querySelector(".segment input:focus"))r();}),
    // condition: ()=>$(".segment input").is(":visible") && ($(".keyboard:focus").is(":visible")||$(".segment input").is(":focus")),
    condition: ()=>document.querySelector(".segment input") && (document.querySelector(".keyboard:focus")||document.querySelector(".segment input:focus")),
    loseCondition: async()=>{
      await new Promise(r=>setTimeout(r,100));
      // if ($(".segment input").is(":visible")){
      if (document.querySelector(".segment input")){
        // const keyboard = await appear(".keyboard");
        const filename = await appear(".filename");
        await filename.tte("<p>It looks like the waveform window lost focus. Please click on the keyboard icon.</p>",{
          y: 'below', x: 'right', click: false, cover: false, promise: r=>document.querySelector(".keyboard").addEventListener("focusin",r) //$(".keyboard").focus(r)
        }).promise;
      }
      else{
        const segmentMidCol = await appear(`//div[contains(@id,'segment-']/div/following-sibling::div`,false,true);
        await segmentMidCol.tte("<p>It looks like you closed the input box. Please click here to reopen it.</p>",{
          click: false, cover: true, y: 'above', promise:r=>segmentMidCol.addEventListener('click',r)
        }).promise;
        await segmentMidCol.tte("<p>Now press <tt>Tab</tt> to bring focus back to the waveform window.</p>",{
          click: false, cover: false, promise: r=>document.querySelector(".keyboard").addEventListener('focusin',r)
        }).promise;
      }
    }
  }).promise;

  // $(".segment input:visible").focus();
  // document.querySelector(".segment input").focus();

  input = await appear(".segment input:focus");
  await input.tte("<p>Now you're back in the text window (notice its red border).</p>\
                   <p>Press <tt>Enter</tt> to play the next audio segment.</p>", {
    cover: false,
    click: false,
    key: "Enter",
    condition: inputCondition,
    loseCondition: inputLoseCondition
  }).promise;

  await checkIfAudioFinishedPlaying();

  await waveform.tte("<p>Let's toggle back to the waveform window: press <tt>Tab</tt>.</p>", {
    cover: false,
    click: false,
    key: "Tab",
    condition: inputCondition,
    loseCondition: inputLoseCondition
  }).promise;

  // const n_underlines = $(".waveform-underlines rect").length;
  const n_underlines = document.querySelectorAll(".waveform-underlines rect").length;
  await waveform.tte("<p>Now press <tt>Enter</tt> and notice what happens!</p>", {
    click: false,
    condition: () => document.querySelector(".keyboard:focus"), // $(".keyboard").is(":focus"),
    loseCondition: async () => await bringFocusToRelevantWindow(waveform, "Waveform"),
    key: "Enter",
    y: "below"
  }).promise;

  const rect = await appear(".waveform-underlines rect:nth-child(" + Number(n_underlines + 1) + ")");
  // A new underline has appeared: there's a new (empty) segment
  const new_segment_id = parseInt($(
    [...document.querySelectorAll(".segment")].sort((a, b) => Number(b.getAttribute('data-iid')) - Number(a.getAttribute('data-iid')))[0]
  ).data("iid"));
  await rect.tte("<p>Unlike in the text window, where <tt>Enter</tt> played the next audio segment,\
      pressing <tt>Enter</tt> with focus on the waveform window just created another copy of the active segment,\
      as indicated by the double blue bar.</p>", {
    click: true,
    cover: true,
    y: "below"
  }).promise;

  // const segments = await appear(".segment");
  // await segments.tte("<p>To deal with this, click in the input box of the newly created segment \
  const new_segment = await appear(".segment.text-red-500");
  await new_segment.tte("<p>To deal with this, click in the input box of the newly created segment \
                                        in the list below (the empty red-colored line).</p>", {
    click: false,
    cover: true,
    y: "above",
    promise: r => new_segment.addEventListener("focusin", r)
    // promise: r => document.addEventListener("focusin", e=>{
    //   if (xpath(`//div[@data-iid='${new_segment_id}']/div/input`)) r();
    // })
    // promise: r => $(".segmentss").on('click focus', `.segment-${new_segment_id} input`, r)
  }).promise;

  input = await appear(".segment input:focus");
  await input.tte("<p>Now press <tt>CTRL</tt>+<tt>d</tt> on your keyboard to delete this unwanted audio segment.</p>", {
    click: false,
    y: "below",
    promise: r => document.addEventListener("keydown", e => { if (e.ctrlKey && e.key === "d") r(); }),
    // condition: ()=>$(`.segment-${new_segment_id} .segment input`).is(":focus"),
    condition: ()=>xpath(`//div[@data-iid='${new_segment_id}']/div/input`),
    loseCondition: async()=>{
      const segmentMidCol = await appear(`//div[@data-iid='${new_segment_id}']/div/following-sibling::div`,false,true);
      await segmentMidCol.tte("<p>It looks like you lost focus from the input box. Click here to get it back.</p>",{
        cover: true,
        y: 'above',
        click: false,
        promise: r=>segmentMidCol.addEventListener('click',r)
      }).promise;
      await appear(".segment input:focus");
    }
  }).promise;

  await waveform.tte("<p>As you can see, the duplicate segment has now disappeared.\
                         You now know how to toggle and delete an unwanted segment.</p>", {
    cover: false, click: true, key: false, y: "above"
  }).promise;

  divide_and_merge_segment();
});

/**
 * @description Splitting and mergin while in Waveform Window
 */
const divide_and_merge_segment = step("Split and Merge Segments: Part I", async function () {
  await openDialog(
    "Split and Merge Segments: Part I",
    "As your transcription work progresses, you will find that the edits you want to make to your segments\
       are not limited to deletion.<br><br>\
       Sometimes, you will create one segment and later realize that splitting it in two would be a better option,\
       or the other way around. Let us learn how to split and merge audio segments."
  );

  let waveform_underlines = await appear(".waveform-underlines");
  await waveform_underlines.tte("<p>Click on the transcription line of an audio segment\
                                    to make it active.</p>", {
    click: false,
    cover: false,
    y: "above",
    promise: r => document.addEventListener('focusin', e=>{if (document.querySelector(".segment input:focus"))r();})
    // promise: r => $(".segmentss").on('focusin', '.segment input', r)
  }).promise;

  const waveform = await appear(".node-waveform");
  await waveform.tte("<p>Now press <tt>Tab</tt> to give focus to the waveform window.</p>", {
    key: "Tab",
    click: false,
    cover: false,
    y: "above"
  }).promise;

  await waveform.tte("<p>Move your mouse over the waveform window to control the red line cursor</p>\
                      <p>and, place it where you want to divide the current segment.</p>\
                      <p>IMPORTANT: do NOT click, simply move the red cursor</p>", {
    click: false, key: false,
    // condition: () => $(".keyboard").is(":focus"),
    condition: () => document.querySelector(".keyboard:focus"),
    loseCondition: async () => await bringFocusToRelevantWindow(waveform, "Waveform"),
    promise: r => waveform.addEventListener('mousemove',r)
  }).promise;

  // $(".keyboard").focus();
  document.querySelector(".keyboard").focus();
  await waveform.tte("<p>Press the comma '<tt>,</tt>' key on your keyboard to split the segment where the cursor is.</p>\
                      <p>IMPORTANT: do NOT click, simply move the cursor and then press '<tt>,</tt>'.</p>", {
    click: false,
    // condition: () => $(".keyboard").is(":focus"),
    condition: () => document.querySelector(".keyboard:focus"),
    loseCondition: async () => await bringFocusToRelevantWindow(waveform, "Waveform"),
    key: ','
  }).promise;

  document.querySelector(".keyboard").focus();

  waveform_underlines = await appear(".waveform-underlines");
  await waveform_underlines.tte("<p>The former active segment has been split in two: there now are two blue bars where there used to be one,\
                         and a new empty transcription line appeared in the list below the waveform.</p>", {
    click: true, key: false, cover: true, y: "above"
  }).promise;

  document.querySelector(".keyboard").focus();
  await waveform.tte("<p>Now that you know how to split segments in two, we will learn to merge them back!<br>\
                         To merge them back, simply press the letter <tt>m</tt> on your keyboard:\
                         this will merge the new active segment with the next one on its right (the empty one).</p>\
                         <p>Note that this command works with waveform focus---framed keyboard icon.</p>", {
    click: false, key: "m", y: 'above', 
    condition: () => document.querySelector(".keyboard:focus"),
    loseCondition: async () => await bringFocusToRelevantWindow(waveform, "Waveform"),
    cover: false
  }).promise;

  await waveform.tte("<p>Good job! Remember, when focus is on the waveform window, <br>\
        a keypress on <tt>,</tt> will split the segment at the red cursor,<br>\
        and a keypress on <tt>m</tt> will merge the next segment into the active segment.</p>", {
    click: true,
    key: false,
    y: "below"
  }).promise;

  divide_and_merge_from_text();
});

/**
 * @description Splitting and mergin while in Text Window
 */
const divide_and_merge_from_text = step("Split and Merge: Part II", async function () {
  await openDialog(
    "Split and Merge: Part II",
    "<p>You now know how to split and merge two segments while you are in the waveform window.</p>\
     <p>Commands work differently in the waveform window and the text window.\
        For example, simply pressing comma in the text window will just type it instead of dividing the segment.</p>\
     <p>So let's see how to do merge and split while focus is on the text window.</p>"
  );

  const segments = await appear(".segment");
  await segments.tte("<p>First, click a segment to open its input box and give it focus.</p>", {
    click: false,
    cover: true,
    y: "above",
    promise: r => document.querySelectorAll(".segment").forEach(n=>n.addEventListener('click', r))
  }).promise;

  const waveform = await appear(".node-waveform");
  await appear(".segment input");
  await waveform.tte("<p>Now move the red line cursor (<em>without clicking</em>) to where you want to split.</p>\
      <p>Then press the Control and comma keys together (<tt>Ctrl</tt>+<tt>,</tt>).</p>", {
    click: false,
    cover: false,
    y: "above",
    // condition: () => $(".segment input").is(":focus"),
    condition: () => document.querySelector(".segment input:focus"),
    loseCondition: async () => await bringFocusToRelevantWindow(waveform, "Input"),
    // promise: r => $(document).on('keyup', '.segment input', e => { if (e.ctrlKey && e.key === ",") r(); })
    // promise: r => document.addEventListener('keyup', e=>{
    promise: r => document.addEventListener('keydown', e=>{
      if (e.ctrlKey && e.key === "," && document.querySelector(".segment input:focus")) r(); 
    })
  }).promise;

  await waveform.tte("<p>You now have two segments.</p>\
                      <p>Press the Control and <tt>m</tt> keys together\
                         (<tt>Ctrl</tt>+<tt>m</tt>) to merge the two split segments.</p>", {
    click: false,
    y: "above",
    // condition: () => $(".segment input").is(":focus"),
    condition: () => document.querySelector(".segment input:focus"),
    loseCondition: async () => await bringFocusToRelevantWindow(waveform, "Input"),
    // promise: r => $('.segment input', e => { if (e.ctrlKey && e.key === "m") r(); })
    promise: r => document.addEventListener('keyup', e=>{
      if (e.ctrlKey && e.key === "m" && document.querySelector(".segment input:focus")) r(); 
    })
  }).promise;

  await waveform.tte("<p>As you can see, the two split segments are now merged into a single one again.</p>\
                      <p>You are now able to split and merge two segments both from within the waveform and\
                      from within the text window.</p>", {
    cover: false, click: true, y: "above"
  }).promise;

  adjust_segments();
});

/**
 * @description Adjusting the already created audio segments to increse or decrease the length
 */
const adjust_segments = step("Adjust Audio Segments", async function () {
  const waveform = await appear(".node-waveform");
  await openDialog(
    "Adjust Audio Segments",
    "You may have noticed that splitting one segment inserts an empty area between the two new segments:\
       this is one situation where you might need to adjust (shorten or lengthen) an existing segment.<br><br>\
       Let us see how to do just that."
  );
  
  const segments = await appear(".segment");
  await segments.tte("<p>First, click on a segment in this list.</p>", {
    click: false,
    cover: true,
    y: "above",
    promise: r => document.querySelectorAll(".segment").forEach(n=>n.addEventListener("click", r))
  }).promise;

  // const input = await appear(".segment input");
  // const n = parseInt(input.parents(".segment").attr("class").replace(/^.*segment-(\d+).*$/, "$1"));
  
  await appear("rect.selection");
  await promise(r=>setTimeout(r,100)); // 100ms timer to leave time to selection region to expand

  await waveform.tte("<p>Now you should see a red region in the waveform.</p>\
                      <p>Click either end of that red region and drag your cusor in either direction.</p>", {
      click: false,
      cover: true,
      promise: r=>{
        let x = NaN;
        document.addEventListener('mousemove', e=>{
          if (!isNaN(x) && Math.abs(e.clientX-x)>5)
            r();
        });
        // $(document).on("mousedown", ".selection-handle", e=>x=e.clientX);
        document.querySelectorAll(".selection-handle").forEach(n=>n.addEventListener("mousedown", e=>x=e.clientX));
      },
      // condition: ()=>$("rect.selection").width()>5,
      condition: ()=>{
        const rect = document.querySelector("rect.selection");
        return rect && parseInt(window.getComputedStyle(rect).width)>5;
      },
      loseCondition:async ()=>{
        await segments.tte("<p>Oops, it looks like you lost the selection region. Simply click on a transcript line.</p>",{
          click: false,
          cover: true,
          y: 'above',
          // promise:r=>$(".segmentss").on('click', '.segment', r)
          promise: r=>document.querySelectorAll(".segment").forEach(n=>n.addEventListener('click', r))
        }).promise;
      }
  }).promise;

  await promise(r=>setTimeout(r,500)); // 500ms timer to leave time to user to see what happens
  await waveform.tte("<p>There you go, it's as simple as that!\
                         Drag in one direction to shorten, drag in the other direction to lengthen.</p>", {
    click: true,
    cover: false,
    y: "below"
  }).promise;

  zoom_in_out();
});

/**
 * @description Zoom funciton for the waveform audio file
 */
const zoom_in_out = step("Zoom In/Zoom Out", async function () {
  const waveform = await appear(".node-waveform");
  await openDialog(
    "Adjust Audio Segments: Zoom In/Zoom Out",
    "Whenever you adjust a segment, you should insert a buffer of 0.1s before and after it:\
       this ensures that a word won't be cut off prematurely.<br><br>\
       Precisely measuring 0.1s can be difficult, so this tool comes with a built-in zoom in/out function."
  );

  // the code below handles keypresses from outside waveform focus
  // would there be a general way of handling loss or required preconditions resulting from unwanted clicks, etc.?
  let pressed_i = false;
  await waveform.tte("<p>To zoom in, make sure you are in the waveform window (framed keyboard icon),<br>\
                         and press the letter key <tt>i</tt> (for '<tt>in</tt>').</p>", {
    click: false,
    y: "below",
    promise: r => document.addEventListener("keydown", e => {
      if (pressed_i == false && e.key === "i") {
        // if ($("div.keyboard:focus").length) {
        if (document.querySelector("div.keyboard:focus")) {
          pressed_i = true;
          r();
        }
        else {
          // $(waveform.tooltips[0]).html("Click the waveform to give it focus, and only then press <tt>i</tt>");
          waveform.tooltips[0].innerHTML = "Click the waveform to give it focus, and only then press <tt>i</tt>.";
          waveform.addEventListener('click', () => {
            if (pressed_i == false)
              // $(waveform.tooltips[0]).html("Now press <tt>i</tt>");
              waveform.tooltips[0].innerHTML = "Now press <tt>i</tt>.";
          });
        }
      }
    })
  }).promise;

  const waveform_ticks = await appear(".waveform-ticks");
  await waveform_ticks.tte("<p>As you can see, the timeline intervals are now finer-grained. You can zoom further in by pressing <tt>i</tt> again.</p>", {
    click: true,
    cover: true
  }).promise;

  // Here we just assume that focus won't get lost in the meantime
  document.querySelector(".keyboard").focus();
  await waveform.tte("<p>To zoom out, press the letter key <tt>o</tt> (for '<tt>out</tt>')<br>\
                         while focus is still on the waveform window (framed keyboard icon).</p>", {
      key: "o",
      click: false,
      cover: false,
      y: "below",
      // condition:()=>$(".keyboard:focus").length>0,
      condition: ()=>document.querySelector(".keyboard:focus"),
      loseCondition: async ()=>{
        const channel = await appear(".ChannelA");
        await channel.tte("<p>Focus needs to be on the waveform window. Click the waveform window to bring it back focus.</p>",{
          click: false,
          cover: true,
          // promise: r=>$(".node-waveform").click(r)
          promise: r=>document.querySelector(".node-waveform").addEventListener('click',r)
        }).promise;
      }
  }).promise;

  await waveform.tte("<p>Remember, <tt>i</tt> to zoom <strong>i</strong>n, <tt>o</tt> to zoom <strong>o</strong>ut.</p>", {
    click: true,
    cover: false,
    key: false,
    y: "below"
  }).promise;

  home_keys_one();
});

/**
 * @description Usage of Home Keys to edit the audio segment
 */
const home_keys_one = step("Home Keys: Part I", async () => {
  await openDialog(
    "Home Keys: Part I",
    "Zooming in and out is not the only way of getting finer-grained control over the waveform.<br><br>\
     In this step, you will learn to control elements from the waveform window using your keyboard."
  );

  // Wait for waveform here, because segmentss takes it place early on
  const waveform = await appear(".node-waveform");
  const segments = await appear(".segment");
  await segments.tte("<p>First, click on one of the transcription lines below.</p>", {
    y: "above",
    click: false,
    cover: true,
    promise: r => document.querySelectorAll(".segment").forEach(n=>n.addEventListener('click',r))
  }).promise;

  const input = await appear(".segment input");
  await input.tte("<p>Now that your segment is active, press <tt>Tab</tt> to give focus to the waveform window.</p>\
             <p>Important: do NOT click the waveform window, or you will lose the active segment.</p>", {
    y: "below",
    cover: false,
    click: false,
    condition: () => input === document.activeElement,
    loseCondition: async () => await bringFocusToRelevantWindow(input, "Input"),
    key: "Tab"
  }).promise;

  await appear(".keyboard:focus");

  const mode = await appear(".mode");
  await mode.tte("<p>Notice how this reads <em>cursor</em>: this means that key bindings will apply to the red cursor.</p>\
                  <p>In this step, we want to adjust the beginning/end of the segment. \
                    Press <tt>b</tt> to control the <strong>b</strong>eginning of the segment.</p>", {
    click: false,
    cover: true,
    y: "below",
    key: "b",
    // condition: ()=>$(".keyboard").is(":focus") && $(".segment input").is(":visible"),
    condition: ()=>document.querySelector(".keyboard:focus") && document.querySelector(".segment input"),
    loseCondition: async ()=>{
      await new Promise(r=>setTimeout(r,100));
      // if ($(".segment input").is(":visible")){
      if (document.querySelector(".segment input")){
        const filename = await appear(".filename");
        await filename.tte("<p>It looks like your waveform window lost focus. Simply click on the keyboard icon.</p>",{
          click: false, y: 'below', x: 'right', cover: false, promise:r=>document.querySelector(".fa-keyboard").addEventListener('click',r)
        }).promise;
      }
      else{
        await segments.tte("<p>It looks like you lost your active segment. Please click on a segment.</p>",{
          click: false, cover: true, y: 'above', promise:r=>document.querySelectorAll(".segment").forEach(n=>n.addEventListener('click',r)) // $(".segmentss").on('click','.segment',r)
        }).promise;
        await waveform.tte("<p>Now press <tt>Tab</tt> to give focus to the waveform window.</p>",{
          click: false, y: 'below', x: 'right', cover: false, key: "Tab"
        }).promise;
      }
    }
  }).promise;

  // await appear(".mode:contains('beg')");
  await modeAppears('beg');
  
  await mode.tte("<p>This now reads <em>beg</em>: you are now controlling the beginning of the segment.</p>\
                  <p>Press the key <tt>f</tt> to move it to the left, or the key <tt>j</tt> to move it to the right.</p>", {
    y: "below",
    cover: true,
    click: false,
    key: ["f","j"],
    // condition: ()=>$(".mode:contains('beg')").is(":visible"),
    condition: ()=>document.querySelector(".mode").innerText=='beg',
    loseCondition: async ()=>{
      await lostMode('beg');
      mode.tooltips[0].querySelector(".content").innerHTML = "<p>Press the key <tt>f</tt> to move it to the left, or the key <tt>j</tt> to move it to the right.</p>";
    }
  }).promise;
  
  await waveform.tte("<p>Press the key <tt>f</tt> to move further to the left, or <tt>j</tt> to move further to the right.\
                         Feel free to practice a little.</p>", {
    cover: false,
    click: true,
    y: "below",
    // promise: r => $(document).click(".tooltip .submit", r)
    promise: r => document.querySelector(".tooltip .submit").addEventListener("click", r)
  }).promise;

  // Click on tooltip lost focus---restore it
  document.querySelector(".keyboard").focus();
  await waveform.tte("<p>You can make bigger steps to the left by using the keys <tt>d</tt>, <tt>s</tt> and <tt>a</tt>,<br>\
                         and to the right using the keys <tt>k</tt>, <tt>l</tt> and <tt>;</tt>.<br>\
                         The relative positions of those keys on a standard US keyboard reflect the magnitude of the step.</p>\
                      <p>Press <tt>c</tt> when you are satisfied to go back to <em>cursor</em> mode, thus validating the new beginning position.</p>", {
    y: "below",
    cover: false,
    click: false,
    key: "c",
    // condition:()=>$(".mode:contains('beg')").is(":visible"),
    condition: ()=>document.querySelector(".mode").innerText=='beg',
    loseCondition: async()=>{
      await lostMode('beg');
    }
  }).promise;

  document.querySelector(".keyboard").focus();
  await mode.tte("<p>Now press the key <tt>e</tt> to control the <strong>e</strong>nd of the segment.</p>", {
    y: "below",
    cover: true,
    click: false,
    key: "e"
  }).promise;

  // await appear(".mode:contains('end')");
  await modeAppears('end');

  await mode.tte("<p>This now reads <em>end</em>: you are now controlling the end of the segment.</p>\
                  <p>As before, press the key <tt>f</tt> to move it to the left, or the key <tt>j</tt> to move it to the right.</p>", {
    y: "below",
    cover: true,
    click: false,
    key: ["f","j"],
    // condition:()=>$(".mode").is(":contains('end')"),
    condition: ()=>document.querySelector(".mode").innerText=='end',
    loseCondition: async()=>{
      await lostMode('end');
    }
  }).promise;

  await waveform.tte("<p>The key bindings are the same: <tt>f</tt>, <tt>d</tt>, <tt>s</tt> and <tt>a</tt> move to the left, \
                         <tt>j</tt>, <tt>k</tt>, <tt>l</tt> and <tt>;</tt> move to the right. \
                         Feel free to practice, and press <tt>c</tt> when you are done.</p>", {
    cover: false,
    y: "below",
    click: false,
    key: "c",
    // condition:()=>$(".mode").is(":contains('end')"),
    condition: ()=>document.querySelector(".mode").innerText=='end',
    loseCondition: async()=>{
      await lostMode('end');
    }
  }).promise;

  home_keys_two();
});

/**
 * @description Usage of Home Keys to move teh waveform cursor
 */
const home_keys_two = step("Home Keys: Part II", async () => {
  await openDialog(
    "Home Keys: Part II",
    "These eight keys (<tt>a</tt>, <tt>s</tt>, <tt>d</tt>, <tt>f</tt> and <tt>j</tt>, <tt>k</tt>, <tt>l</tt>, <tt>;</tt>)\
     are called the <em>home keys</em>. You just saw how you can use them to control the beginning and the end of a segment,\
     you will now see how to use them to scroll the waveform window and control the red cursor's position."
  );

  // Wait for waveform here, because segmentss takes it place early on
  const waveform = await appear(".node-waveform");
  await waveform.tte("<p>First, click anywhere in the waveform window.</p>", {
    click: false,
    cover: true,
    key: false,
    promise: r => waveform.addEventListener('click',r)
  }).promise;

  const mode = await appear(".mode");
  await mode.tte("<p>Now press <tt>w</tt> to change from cursor to <em>window</em> mode.</p>", {
    click: false,
    cover: true,
    y: "below",
    key: "w"
  }).promise;

  // await appear(".mode:contains('window')");
  await modeAppears('window');
  let nextClick = false;
  // $(document).mousedown(".tooltip .submit", ()=>nextClick=true).mouseup(".tooltip .submit", ()=>nextClick=false);
  document.addEventListener("mousedown", e=>{if (e.target==document.querySelector(".tooltip .submit")) nextClick=true;});
  document.addEventListener("mouseup", e=>{if (e.target==document.querySelector(".tooltip .submit")) nextClick=false;});
  await waveform.tte("<p>You can now use the home keys to scroll the waveform window \
                         to the right (<tt>j</tt>, <tt>k</tt>, <tt>l</tt> and <tt>;</tt>)\
                         and to the left (<tt>f</tt>, <tt>d</tt>, <tt>s</tt> and <tt>a</tt>).</p>", {
    click: true,
    cover: false,
    key: false,
    // condition:()=>($(".mode").is(":contains('window')")&&$(".node-waveform").is(":visible"))||nextClick,
    condition: ()=>nextClick||(document.querySelector(".mode").innerText=='window'&&document.querySelector(".node-waveform").isVisible()),
    loseCondition: async()=>{
      if (nextClick) return;
      // if ($("#help_screen").is(":visible")){
      if (document.querySelector("#help_screen") && document.querySelector("#help_screen").isVisible()){
        const help = await appear("#help_screen");
        await help.tte("<p>You opened the help menu: press <tt>h</tt> until you get back to the waveform window.</p>",{
          click: false,
          cover: false,
          y: 'top',
          promise: r=>appear(".ChannelA").then(r)
        }).promise;
      }
      else if (document.querySelector(".keyboard:focus")){
      // else if ($(".keyboard").is(":focus")){
        if (mode.tooltips[0] && mode.tooltips[0].isVisible()) return;
        mode.tte("<p>You lost the window mode: press <tt>w</tt> to switch to it again.</p>",{
          click: false,
          cover: false,
          y: 'below',
          promise: r=>{
            // appear(".mode:contains('window')").then(r);
            modeAppears("window").then(r);
            document.querySelector(".keyboard").addEventListener('blur',r);
            waveform.tooltips[0].querySelector(".submit").addEventListener('click',r);
          }
        });
      }
      else {
        const channel = await appear(".ChannelA");
        await channel.tte("<p>Looks like you lost focus from the waveform window. Click anyhere inside it.</p>",{
          click: false,
          cover: true,
          y: 'below',
          // promise:r=>$(".node-waveform").click(r)
          promise: r=>document.querySelector(".node-waveform").addEventListener('click',r)
        }).promise;
        await mode.tte("<p>Now press <tt>w</tt> to retrieve the window mode.</p>", {
          click: false,
          cover: true,
          y: 'below',
          key:'w'
        }).promise;
      }
    }
  }).promise;
  
  document.querySelector(".keyboard").focus();
  // await appear(".mode:contains('cursor')");
  await modeAppears('cursor');

  await mode.tte("<p>In cursor mode, the home keys will simply move the red cursor, allowing you for example\
                     to precisely reach a splitting point. Try pressing one of the home keys and see the cursor move.</p>", {
    click: false,
    cover: true,
    y: "below",
    key: ["a", "s", "d", "f", "j", "k", "l", ";"]
  }).promise;

  await waveform.tte("<p>That's pretty much it for the home keys. \
                         Remember, they will work when focus is on the waveform window (framed keyboard icon).</p>\
                      <p>Feel free to practice a little more before moving to the next step.</p>", {
    click: true,
    cover: false,
    key: false
  }).promise;

  move_audio_segment();
});

/**
 * @description Steps related to keys which perform same action across both the windows
 */
const move_audio_segment = step("Move Across Audio Segments", async function () {
  await openDialog(
    "Move Across Audio Segments",
    "A few keys perform the same action when pressed from <em>either</em> window.<br><br>\
       Pressing the up and down arrow keys from either window, for example, will move from one audio segment to another."
  );

  const waveform = await appear(".node-waveform");
  await waveform.tte("<p>First make sure your focus is either on the waveform window or on the text window.</p>", {
    click: false,
    y: "above",
    promise: r => {
      // $(".segmentss").on("focusin", ".segment input", r);
      // $("div.keyboard").focus(r);
      document.addEventListener("focusin", e=>{if(document.querySelector(".segment input:focus"))r();});
      document.querySelector(".keyboard").addEventListener('focusin',r);
    }
  }).promise;

  await waveform.tte("<p>Now press the <tt>Up</tt> arrow key to go to the last/previous segment,<br>\
                         or the <tt>Down</tt> arrow key to go the first/next segment.</p>", {
    click: false,
    y: "above",
    key: ["ArrowUp", "ArrowDown"]
  }).promise;

  await waveform.tte("<p>You can try switching focus and press <tt>Up</tt> or <tt>Down</tt> again if you'd like.</p>\
                      <p>Note that pressing either key will automatically bring focus back to the input window,\
                         so you need to toggle focus if you want to work from the waveform window.</p>\
                      Once you are ready, we will move to the next step.", {
    click: true,
    key: false,
    y: "above"
  }).promise;

  open_help();
});

/**
 * @description Describe the first 2 help menu options
 */
const open_help = step("Help Menu: General", async function () {
  await openDialog(
    "Help Menu: General",
    "You might forget some key bindings, and there are some that you are not familiar with yet.<br><br>\
     You can review the different key bindings from the help menu. Let us see how to do that."
  );

  const waveform = await appear(".node-waveform");
  await waveform.tte("<p>First, make sure your focus is on the waveform window (framed keyboard icon).</p>\
                      <p>Then press the <tt>h</tt> key to open the help menu. </p>", {
    click: false,
    promise: r => {
      const helpAppears = ()=>{
        const h4 = document.querySelector("h4");
        // if (h4.textContent==="Main Help") r();
        if(document.querySelectorAll("h4").length > 0) r();
        else window.requestAnimationFrame(helpAppears);
      };
      helpAppears();
    }
    // appear("h4:contains('Main Help')").then(r) //appear("#help_screen").then(r)
  }).promise;

  const loseHelpScreen = async()=>{
    const channel = await appear(".ChannelA");
    await channel.tte("<p>It looks like you quit the help menu. First, click the waveform window.</p>",{
      click: false, cover: true, y: 'below', promise: r=>document.querySelector(".node-waveform").addEventListener('click',r)
    }).promise;
    await channel.tte("<p>Now, press the <tt>h</tt> key.</p>",{
      click: false, cover: false, y: 'below', key: 'h'
    }).promise;
  }

  // const mini_screen = await appear("#help_screen");
  // const mini_screen = await appear(".view");
  const mini_screen = await appear("//h4[.='Main Help']",false,true);
  await mini_screen.tte("<p>Now press the number <tt>1</tt> on your keyboard to get help about the waveform window.</p>", {
    click: false,
    y: 'above',
    // promise: r => appear("#keystrokes + p").then(r),
    promise: r => appear("//h4[.='Waveform Help']",false,true).then(r),
    // condition:()=>$("h4:contains('Main Help')").is(":visible"),//$("#help_screen").is(":visible"),
    condition: ()=>document.querySelector("h4")&&document.querySelector("h4").innerText.match(/\w+ Help/),
    loseCondition: loseHelpScreen
  }).promise;

  // const keystrokes = await appear("#keystrokes + p");
  // await keystrokes.tte("<p>This paragraph summarizes the keys and their actions from the waveform window</p>\
  // await mini_screen.tte("<p>This page summarizes the keys and their actions from the waveform window</p>\
  // const help_screen = await appear("#help_screen");
  const help_screen = await appear("//h4[.='Waveform Help']",false,true);
  await help_screen.tte("<p>This page summarizes the keys and their actions from the waveform window.</p>\
                        <p>Press <tt>h</tt> when you are done reading to go back to the help menu.</p>", {
    key: "h",
    click: false,
    cover: false,
    y: "above",
    // condition:()=>$("#help_screen").is(":visible"),
    // condition:()=>document.querySelector("#help_screen")&&document.querySelector("#help_screen").isVisible(),
    condition: ()=>document.querySelector("h4")&&document.querySelector("h4").innerText.match(/\w+ Help/),
    loseCondition: async()=>{
      const h4 = document.querySelector("h4");
      if (!h4 || !h4.innerText.match(/\w+ Help/) || !h4.isVisible())
        await loseHelpScreen();
      const root = await appear(".Root");
      await root.tte("<p>Now press <tt>1</tt> to get back to the summary page.</p>",{
        click: false, cover: true, y: 'below', key: '1'
      }).promise;
    }
  }).promise;

  await mini_screen.tte("<p>Now press the number <tt>2</tt> key on your keyboard to get help about the text window.</p>", {
    key: "2",
    click: false,
    y: 'below',
    // condition:()=>$("h4:contains('Main Help')").is(":visible"),
    condition: ()=>{
      const h4 = document.querySelector("h4");
      return h4.innerText.match(/\w+ Help/) && h4.isVisible();
      // return h4.innerText=='Main Help' && h4.isVisible();
    },
    loseCondition: loseHelpScreen
  }).promise;

  const main_help = await appear("//h4[.='Transcript Input Help']",false,true);
  await main_help.tte("<p>This lists the key bindings from the text window. Press <tt>h</tt> again to go back.</p>", {
    key: "h",
    click: false,
    y: "above",
    condition: ()=>{
      // const help_screen = document.querySelector("#help_screen");
      // return help_screen && help_screen.isVisible();
      const h4 = document.querySelector("h4");
      return h4.innerText.match(/Transcript Input Help/) && h4.isVisible();
    },
    loseCondition: async()=>{
      const h4 = document.querySelector("h4");
      if (!h4 || !h4.innerText.match(/\w+ Help/) || !h4.isVisible())
        await loseHelpScreen();
      const root = await appear(".Root");
      await root.tte("<p>Now press <tt>2</tt> to get back to the key bindings page.</p>",{
        click: false, cover: true, y: 'above', key: '2'
      }).promise;
    }
  }).promise;
  // sad_help();
  close_file();
});

//
// const sad_help = step("Help Menu: SAD", async function(){
//   await openDialog(
//       "Help Menu: SAD",
//       "Another important option from the help menu is SAD.<br><br>\
//        SAD is the automatic segmentor. It can help you automatically divide the whole audio file in multiple segments.\
//        One thing to remember is that SAD is really good, but it is not perfect, so you will still need all the skills you have just learned."
//   );
//   const waveform = await appear(".node-waveform");
//   await waveform.tte("<p>To use SAD, first go to the help menu by pressing the <tt>h</tt> key when in the waveform window</p>", {
//       click: false,
//       promise:r=>$(".Root").keydown(e=>{if ($(".keyboard:focus").length && e.key=="h") r();})
//   }).promise;
//   const section_list = await appear("#section ~ ol li:nth-child(4)");
//   await section_list.tte("<p>Now press the number key <tt>4</tt> on your keyboard to open services menu.</p>", {
//       y: "below",
//       key: "4",
//       click: false
//   }).promise;
//   const sad = await appear("li:contains('SAD')");
//   await sad.tte("<p>Now press the number key <tt>1</tt> on your keyboard to use SAD.</p>", {
//       key: "1",
//       click: false
//   }).promise;
//   await waveform.tte("<p>Now just wait for SAD to finish up, and you will have your segmented file.</p>", {
//     y: "above", click: true
//   }).promise;
//   close_file();
// });
//

const close_file = step("Submit your work", async function(){
  await openDialog(
    "Help Menu: Submit",
    "We are almost done! There's one last thing we need to see: how to submit your transcription."
  );

  // CHANGE THIS, SINCE END BUTTON IS NO LONGER IN HELP MENU

  // const submit = await appear(".filename + div div:nth-child(3) button");
  const submit = await appear("//div[following-sibling::*[1][contains(@class,'mode')]]/button",false,true);
  await submit.tte("<p>When you are done with the file, click this checkmark icon to submit your work.</p>", {
    click: false, cover: true,
    // promise: r => document.querySelector(".filename + div div:nth-child(3) button").addEventListener('click',r)
    promise: r => xpath("//div[following-sibling::*[1][contains(@class,'mode')]]/button").addEventListener('click',r)
  }).promise;
  
  const done = await appear("//button[.='Done']",false,true);
  await done.tte("<p>Unless there was a problem with the file, simply click on 'Done'.</p>", {
    click: false, cover: true, y: "above",
    condition: ()=>{
      const h4 = document.querySelector("h4");
      return h4.innerText.match(/Close Transcript, Move to Next File/) && h4.isVisible();
    },
    loseCondition: async()=>{
      const submitC = await appear(".filename + div div:nth-child(3)");
      await submitC.tte("<p>It looks like you closed the popup. Click on the checkmark icon to reopen it.</p>",{
        click: false, cover: true, y: 'below', promise: r=>submitC.addEventListener('click',r)
      }).promise;
    },
    promise: r=>done.addEventListener('click',r)
  }).promise;

  end();
});

/**
 * @description Describe the usage of SAD from help menu
 */
const end = step("End", async function () {
  await openDialog(
    "Training complete!",
    "<p>Thank you, this is the end of this transcription training guide!\
      Remember, you can always press <tt>h</tt> while in the waveform window to get help with the interface.</p>\
     <p>If you wish to take the tutorial again, simply leave this task and open it again.</p>"
  );

  // Add something to automatically reset this guide?
  return 'end';
});



// FUNCTION DEFINITIONS AND GUIDE PRIORITY HANDLING
//
let dialog = null;
const openDialog = (title, content, modal = true) => promise(r => {
  // if (dialog instanceof jQuery && dialog.is(":visible"))
  //   dialog.dialog("close");
  if (dialog && dialog.isVisible())
    dialog.dialog("close");
  // dialog = $("<div>").appendTo($("body")).html(content);
  dialog = document.createElement("DIV");
  dialog.innerHTML = content;
  document.body.append(dialog);
  dialog.dialog({
    title: title,
    resizable: true,
    width: 600,
    closeOnEscape: false,
    modal: modal,
    buttons: { Next: function () { this.dialog("close"); r(); } }
  });
  return dialog;
});

const getSelectionAndFocusBack = async ()=>{
  const rect = document.querySelector("rect.selection");
  if (rect && parseInt(window.getComputedStyle(rect).width)<5){
    const channel = await appear(".ChannelA");
    await channel.tte("<p>It looks like you lost the selection. No worries, simply move your cursor over the waveform window,\
                           click, drag your cursor and then release.</p>", {
      click: false,
      cover: true,
      promise: r=>selectionHappened(r)
    }).promise;
  }
  else {
    const keyboard = await appear(".fa-keyboard");
    await keyboard.tte("<p>It looks like the waveform window lost focus. Please click on this keyboard icon.</p>", {
      click: false,
      cover: true,
      promise: r=>document.querySelector(".keyboard").addEventListener('click',r)
    }).promise;
  }
};

const selectionHappened=r=>{
  const callback = async ()=>{
    const selection = await appear("rect.selection");
    if (parseInt(window.getComputedStyle(selection).width)>5){
      document.querySelector(".node-waveform").addEventListener('mouseleave',r);
      document.addEventListener('mouseup',r);
    }
    else window.requestAnimationFrame(callback);
  };
  callback();
};

const modeAppears = mode => new Promise(r=>{
  const check = ()=>{
    const node = document.querySelector('.mode');
    if (node.textContent===mode) r();
    else window.requestAnimationFrame(check);
  };
  check();
});

const lostMode = async check_mode => {
  const filename = await appear(".filename"); // Do not overwrite original f/j key promise
  await filename.tte("<p>It looks like you quit <em>" + check_mode + "</em> mode. Let's get it back.</p>", {
    y: "below", x: 'right', cover: false, key: false, click: true
  }).promise;

  const segments = await appear(".segment");
  await segments.tte("<p>Click on one of the transcription lines below.</p>", {
    y: "above", cover: true, key: false, click: false,
    // promise: r => $(".segment").click(r)
    promise: r => document.querySelectorAll(".segment").forEach(n=>n.addEventListener('click',r))
  }).promise;

  await appear(".segment input");
  const channel = await appear(".ChannelA");
  await channel.tte("<p>Now do NOT move your mouse cursor and press <tt>Tab</tt>.</p>", {
    y: "below", cover: false, key: "Tab", click: false
  }).promise;

  await appear(".keyboard:focus");
  await channel.tte("<p>Keep NOT moving your mouse cursor and press <strong><tt>" + check_mode[0] + "</tt></strong>.</p>", {
    y: "below", cover: false, key: check_mode[0], click: false
  }).promise;

  // await appear(".mode:contains('" + check_mode + "')");
  await modeAppears(check_mode);
}

const bringFocusToRelevantWindow = async (currentTooltip, window) => {
  let current_window_selector = "";
  let focus_selector = "";

  if(window == "Waveform"){
      current_window_selector = ".fa-keyboard";
      focus_selector = ".keyboard";
  } else if(window == "Input") {
      current_window_selector = ".segment input";
      focus_selector = ".segment input";
  }

  const current_window = await appear(current_window_selector);
  await current_window.tte(
    "<p>It looks like you lost focus from the " + window +" window.</p>\
        <p>Let us bring it back: simply click here to bring focus back to the "+ window +" window.</p>", {
    click: false, cover: true,
    // promise: r3 => $(document).on('focusin', focus_selector, r3)
    promise: r3 => document.addEventListener('focusin', e=>{
      const focus_element = document.querySelector(focus_selector);
      if (focus_element && focus_element===document.activeElement) r3();
    })
  }).promise;

  // const oldText = $(currentTooltip.tooltips[0]).find('div.content').text().replace(/Focus is back on the \w+ window./,'');
  // $(currentTooltip.tooltips[0]).find('div.content').html(`<p>Focus is back on the ${window} window.</p><p>${oldText}</p>`);
  const contentDiv = currentTooltip.tooltips[0].querySelector("div.content");
  const oldText = contentDiv.innerText.replace(/Focus is back on the \w+ window./,'');
  contentDiv.innerHTML = `<p>Focus is back on the ${window} window.</p><p>${oldText}</p>`;
}

const lostBlueBar = async (currentTooltip, n) => {
  const waveform_frame = await appear(".view");
  await waveform_frame.tte("<p>Looks like you lost the blue bar!</p>\
                      <p>Don't worry, we'll get it back. First, click anywhere inside the waveform.</p>", {
    // promise: r3 => $(".waveform-svg").click(r3),
    promise: r3 => document.querySelector(".waveform-svg").addEventListener('click',r3),
    click: false
  }).promise;

  let transcription_line = await appear(`//div[@id='segment-${n}']`,false,true);
  await transcription_line.tte("<p>Good, now click on this transcription line.</p>", {
    promise: r3 => transcription_line.addEventListener('click',r3), cover: true, click: false
  }).promise;

  await appear(".underline-rect-" + (n + 1));
  // $(currentTooltip.tooltips[0]).find('div.content').html("<p>The blue bar is back!</p>\
  currentTooltip.tooltips[0].querySelector('div.content').innerHTML = "<p>The blue bar is back!</p>\
    <p>You can now click either end of that red region and drag your cusor in either direction.</p>";
}

const checkIfAudioFinishedPlaying = () => promise(r => {
  const callback_stop = () => {
    if (is_playing() == false)
      r();
    else
      window.requestAnimationFrame(callback_stop);
  };
  const callback_start = () => {
    if (is_playing() == true)
      callback_stop();
    else
      window.requestAnimationFrame(callback_start)
  }
  callback_start();
})

const set_is_playing = ()=>{
  if (!window.ldc || !window.ldc.waveforms || window.ldc.waveforms.length==0 || !window.ldc.waveforms[0].is_playing)
    window.requestAnimationFrame(set_is_playing);
  else{
    is_playing = window.ldc.waveforms[0].is_playing;
    console.log("is_playing now", is_playing);
  }
}
set_is_playing();


Function.prototype.extend = function (newf) {
  let that = this;
  const returnfn = function (...args) {
    newf.apply(this, args);
    return that.apply(this, args);
  }
  return returnfn;
}

// Halt all other guides
let canInitOtherGuides = false;
Guide.before_init(() => {
  if (!isTaskPage()) return;
  for (let g in Guide.guides) {
    let i = Guide.guides[g].init;
    Guide.guides[g].init = () => {
      if (canInitOtherGuides || Guide.guides[g] == tuto) i.call(Guide.guides[g]);
    }
    Guide.guides[g].halt();
  }
});

const init_guides = () => {
  if (!isTaskPage()) return;
  canInitOtherGuides = true;
  for (let g in Guide.guides)
    if (Guide.guides[g] != tuto) {
      Guide.guides[g]._halted = false;
      Guide.guides[g].init();
    }
}
tuto.complete = tuto.complete.extend(init_guides);
tuto.dismiss = tuto.dismiss.extend(() => {
  if (dialog) dialog.dialog("close");
  init_guides();
});
// tuto._resetButton.click(() => {
tuto._resetButton.addEventListener('click', () => {
  // tuto._resetDialogBox.html("CAUTION: This will erase all your transcript lines\
  tuto._resetDialogBox.innerHTML = "CAUTION: This will erase all your transcript lines\
                                    and go back to the first step of this tutorial.\
                                    Are you sure you want to reset?";
                                    // Are you sure you want to reset?");
});
tuto.reset = tuto.reset.extend(()=>{
  deleteNodesAfter(3);
  try {
    const misc = JSON.parse(tuto._misc);
    misc.lastNodes = [];
    tuto._misc = JSON.stringify(misc);
  }
  catch {}
});
let ready_turoblinks_once = false;
const start = async () => {
  if (document.readyState!="complete") return window.requestAnimationFrame(start);
  console.log("document is ready");
  if (ready_turoblinks_once) return;
  ready_turoblinks_once = true;
  console.log("training: page is ready");
  if (!isTaskPage()) {
    canInitOtherGuides = true;
    return tuto.halt();
  }
  console.log("training: page is task page");
  // Wait until after workflow_open, so that root.data.obj is defined
  const obj = await new Promise(r =>{
    const set_obj = ()=>{
      let o = $(".Root").data("obj");
      if (o === undefined) window.requestAnimationFrame(set_obj);
      else r(o);
    }
    set_obj();
  });
  console.log("training: workflow_open has been extended");
  if (!obj.task_meta || obj.task_meta.notes != "training")
    return init_guides();   // Don't start this guide if not a "training" task
  console.log("training: this is a training task");
  tuto._halted = false;
  tuto.init();
  tuto.after_data(data=>{
    if (data.complete===true) {
      tuto.reset();  // Restart the tuto automatically after completing it  
      tuto.launch();
    }
  });
  tuto._dismissButton.remove();
}
start();

console.log("training.js over");
