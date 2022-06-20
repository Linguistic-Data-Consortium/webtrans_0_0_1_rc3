<script>
  export let chapter;
  export let active = false;
  export let last_chapter;
  export let centers_batteries;

  const admin = window.permissions && window.permissions.dataset.admin=="true";
  
  let adding_battery = false;
  let show_select = true;

  // const centers_batteries = [
  //   {name: 'FTDC', batteries: ['FTDC-core','FTDC-extra cog']},
  //   // {name: 'FTDC', batteries: ['FTDC-extra cog']},
  //   {name: 'PDC', batteries: ['Cookie']},
  //   // {name: 'CReATe', batteries: []}
  // ];
  const get_batteries_for_center = c => {
    let entries = centers_batteries.filter(cs=>cs.name==c);
    if (entries.length==0) entries = [{batteries: []}];
    return entries[0].batteries;
  }
  let current_batteries = [];
  if (last_chapter.center !== undefined)
    current_batteries = get_batteries_for_center(last_chapter.center);

  function selectCenter(e){
    const center = e.target.options[e.target.selectedIndex].text;
    current_batteries = get_batteries_for_center(center);
    show_select = true;
    last_chapter.center = center;
  }
  function selectBattery(e){
    show_select = false;
    const battery = e.target.selectedOptions[0].text;
    if (e.target.selectedOptions[0].id=="freeText"){
      adding_battery = true;
      last_chapter.battery = "";
    }
    else{
      adding_battery = false;
      last_chapter.battery = battery;
    }
  }
  function typeBattery(e){
    const battery = e.target.value;
    console.log("typed battery", battery);
    last_chapter.battery = battery;
  }
  function selectDate(e){
    last_chapter.date = e.target.value;
  }
  function selectTime(e){
    last_chapter.time = e.target.value;
  }
</script>

<div style="display: {active?'block':'none'};" class="chapter">
  
  <label for="collected_url_center">Center for Chapter #{chapter+1}</label>
  <!-- svelte-ignore a11y-no-onchange -->
  <select name="collected_url[center][chapter_{chapter+1}]" id="collected_url_center" on:change={selectCenter}>
    {#if last_chapter.center===undefined}
      <option value='' disabled hidden selected></option>
    {/if}
    {#each centers_batteries as center_battery}
      {#if last_chapter.center==center_battery.name}
        <option value="{center_battery.name}" selected>{center_battery.name}</option>
      {:else}
        <option value="{center_battery.name}">{center_battery.name}</option>
      {/if}
    {/each}
  </select>
  <div>Which center this battery is attached to</div>

  <br>

  <div style="visibility: {current_batteries.length>0?'visible':'hidden'};">
    <label for="collected_url_session_type">Battery for Chapter #{chapter+1}</label>
    <select name="collected_url[session_type][chapter_{chapter+1}]" id="collected_url_session_type" on:change={selectBattery}>
      {#each current_batteries as battery}
        <option value="{battery}">{battery}</option>
      {/each}
      {#if admin}
        <option id='freeText' value="{last_chapter.battery}">Add new battery...</option>
      {/if}
      {#if show_select}
        <option disabled selected value> -- select a battery -- </option>
      {/if}
    </select>
    {#if adding_battery}
      <input type='text' on:input={typeBattery} autofocus />
    {/if}
  </div>

  {#if adding_battery}
    {#if last_chapter.battery.match(/^[\s\t]*$/)}
      <div>Please enter a battery name</div>
    {:else if get_batteries_for_center(last_chapter.center)
                .map(v=>v.toLowerCase()).indexOf(last_chapter.battery.toLowerCase())>=0}
      <div>This battery name already exists</div>
    {/if}
  {/if}
  
  <br>

  <!-- <label for="collected_url_when">Date &amp; Time of battery for Chapter #{chapter+1}</label> -->
  
  <input style='display:none;' type="date" name="collected_url[starts_at_date][chapter_{chapter+1}]" id="collected_url_starts_at_date" on:change={selectDate} value={(new Date()).toISOString().substr(0, 10)} />
  <input style='display:none;' type="time" name="collected_url[starts_at_time][chapter_{chapter+1}]" id="collected_url_starts_at_time" on:change={selectTime} value={(new Date()).toISOString().substr(11, 5)} />

  <br>
</div>
