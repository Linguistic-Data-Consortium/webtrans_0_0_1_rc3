<script>
  import Chapter from './chapter.svelte';

  let token = document.querySelector("meta[name='csrf-token']").content;

  let n_chapters = 1;
  let chapter = 0;

  const last_chapter = {};

  let centers_batteries = [];
  async function get_centers_batteries () {
    console.log("get_centers_batteries");
    let response = await fetch(`${window.location.href.replace(/([^/])$/,"$1/")}public_fields`);
    let array = await response.json();
    let centers = {}
    array.forEach( cb => {
      let center = cb[0];
      let battery = cb[1];
      if (center==null||center==undefined||center=="") return;
      if (center.match("=>")) center = JSON.parse(center.replace(/=>/g,':'));
      else center = {chapter_1: center};
      if (typeof(battery)=="string"&&battery.length>0){
        if (battery.match("=>")) battery = JSON.parse(battery.replace(/=>/g,':'));
        else battery = {chapter_1: battery};
      }
      else{
        battery = {};
        for (let c in center) battery[c] = null;
      }
      for (let c in center){
        let name = center[c];
        centers[name] = (centers[name]||[]);
        if (battery && battery[c] && centers[name].indexOf(battery[c])<0) 
          centers[name].push(battery[c]);
      }
    });
    for (let c in centers)
      centers_batteries.push({name: c, batteries: centers[c]});
  }

</script>

<div class='cleanbox'>
  
  <h1>Report Bluejeans sessions</h1>
  
  <form class="new_collected_url" id="new_collected_url" action="/collected_urls" accept-charset="UTF-8" method="post">
    <input name="utf8" type="hidden" value="✓" />
    <input type="hidden" name="authenticity_token" value="{token}" />

    <label for="collected_url_url">Bluejeans URL</label>
    <input placeholder="https://bluejeans.com/s/xxxxx" class="form-control" type="text" name="collected_url[url]" id="collected_url_url" style="background-image: url(&quot;data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAvElEQVQ4T2NkoBAwIukXALL9gViBgJkPgPIbgfgDSB2yAQVAfj+RDioEqpuAbkADUKAeiB0JGLIfKN8IxCD1KC6AGYDsqgtANf+B2BDJUBCfaAM2QDUGkGMAcpjA/Qx1EVEugHkJZDlcA7EGgKJSHi0wHwL5D4g1wAGoEISRwQEgB4SJCkSQZns0Aw6SYgDICyCMDEDOJ8oL6E5HMwfsDayxQHFSBmUmUIJBdzq6C0DeWAATRE626AqJ4gMAKh82EQu8MAEAAAAASUVORK5CYII=&quot;); background-repeat: no-repeat; background-attachment: scroll; background-size: 16px 18px; background-position: 98% 50%;">
    <div>
      format: <tt style="font-size: 1.25em;">https://bluejeans.com/s/<strong>xxxxx</strong></tt>
      <br>
      where <strong>xxxxx</strong> is a sequence of five or more letters, numbers, and symbols
      (copy and paste from your Bluejeans account)
    </div>

    <br>

    <label for="collected_url_coordinator">Coordinator's name</label>
    <input value="{document.querySelector("#current_user_name").innerText}" class="form-control" type="text" name="collected_url[coordinator]" id="collected_url_coordinator">
    <!-- <div>Coordinator's name</div> -->
    <div></div>

    <br>

    <label for="collected_url_inddid">INDD ID</label>
    <input class="form-control" type="text" name="collected_url[inddid]" id="collected_url_inddid">
    <div>Subject's INDD ID</div>

    <br>

    {#await get_centers_batteries() then value}
      <div class="chapter_buttons">
        {#each Array(n_chapters) as _, n_chapter}
          <input type='button' value="Chapter {n_chapter+1}" class="chapter_button {chapter==n_chapter?'active':'inactive'}" on:click={()=>chapter=n_chapter} />
        {/each}
        <input type="button" value="Add another chapter" on:click={()=>{n_chapters++; chapter=n_chapters-1;}} />
      </div>
      {#each Array(n_chapters) as _, n_chapter}
        <Chapter chapter={n_chapter} active={chapter==n_chapter} {last_chapter} {centers_batteries} />
      {/each}

      <br>

      <label for="collected_url_comment">Comments</label>
      <textarea class="form-control" prefill="Type any comments about the session here" name="collected_url[comment]" id="collected_url_comment"></textarea>
      <div>Type any comments you have about the recordings here</div>

      <br>

      <input type="submit" name="commit" value="Send report" data-disable-with="Send report" />
    {/await}
  </form>
</div>
