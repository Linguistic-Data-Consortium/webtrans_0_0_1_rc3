import { Keyboard } from '../work/keyboard'
import { segments, undefined_segments, sections } from '../waveform/stores'
import { add_source_audio_collision } from '../work/sources_stores'

function update_segments(){
    const o = segment_list_f('segments');
    segments.update( (x) => o.segments );
    undefined_segments.update( (x) => o.undefined_segments );
    sections.update( (x) => o.sections );
}

function update_segments2(json){
  const ns = window.ldc.ns;
  json.map( (x) => x.readonly = true );
  index_segments(json, ns);
  // let sections = Object.values(ns.index_sections_by_name);
  // ns.main.set_segments(json, sections, 'readonly');
  segments.update( (x) => json );
}

function segment_list_f(show){
  const ns = window.ldc.ns;
  // if(!($(".ChannelA").length > 0)) return;
  const pair = create_segments();
  const segments = pair[0];
  const undefined_segments = pair[1];
  index_segments(segments, ns);
  const sections = (function() {
    const ref = ns.index_sections_by_name;
    const results = [];
    for (let k in ref) {
      let v = ref[k];
      results.push(v);
    }
    return results;
  })();
  console.log("INDEX");
  console.log(that.index_sections_by_name);
  console.log('TEST');
  console.log(segments);
  console.log(sections);
  const o = {
    segments: segments,
    undefined_segments: undefined_segments,
    sections: sections,
    show: show
  };
  return o;
  // ns.main.set_segments(segments, sections, show);
}
 
function create_segments() {
  const vars = window.ldc.vars;
  const sel1 = `.${vars.add_from_waveform_list}Item`;
  const sel2 = `.${vars.add_from_waveform_audio}`;
  const sel3 = `.${vars.add_from_waveform_text}`;
  const sel4 = ".Speaker";
  const segments = [];
  const undefined_segments = [];
  $(sel1).each(function(i, x) {
    const data = $(x).find(sel2).data();
    const src = data.value;
    if(!src.beg){
      undefined_segments.push($(x).data().meta.id);
      return;
    }
    const c1 = {
      id: `unsorted-${i}`,
      iid: $(x).data().meta.id,
      docid: src.docid,
      beg: src.beg,
      end: src.end,
      text: $(x).find(sel3).data().value.value || '',
      speaker: $(x).find(sel4).data().value.value || '',
      section: null,
      error: null
    };
    let n1 = c1.text.match(/\(/g);
    if(!n1) n1 = [];
    let n2 = c1.text.match(/\)/g);
    if(!n2) n2 = [];
    if(c1.text && n1.length != n2.length) c1.error = "unbalanced parens";
    // if(c1.text && n1 && n2) c1.error = 'x'
    segments.push(c1);
  });
  segments.sort( (x, y) => x.beg - y.beg );
  return [ segments, undefined_segments ];
}
 
function index_segments(segments, ns){
  const that = ns;
  that.index = new Map();
  that.index2 = new Map();
  that.index3 = new Map();
  const w = that.waveform;
  w.set_playing_transcript_line_index = that.index;
  that.index_segments_by_id = new Map();
  // active = w.set_active_transcript_line null
  let active = w.segments ? w.segments.get_active() : null;
  let aactive = null;
  let aaactive = null;
  if (active && $(`#${active}`).length) {
    aactive = String($(`#${active}`).data().iid);
  }
  w.map = new Map();
  w.rmap = new Map();
  let i;
  let j;
  let ref;
  let c1;
  for (i = j = 0, ref = segments.length; (0 <= ref ? j < ref : j > ref); i = 0 <= ref ? ++j : --j) {
    c1 = segments[i];
    c1.id = `segment-${i}`;
    that.index_segments_by_id.set(c1.id, c1);
    // that.index_segments_by_id[id] = c1
    let node_id = `node-${c1.iid}`;
    w.map.set(c1.id, node_id);
    w.rmap.set(node_id, c1.id);
    that.index.set(c1.beg, [c1.end, c1.id]);
    that.index2.set(String(i), c1);
    that.index3.set(c1.id, String(i));
    if (aactive === c1.iid) {
      // active = id if active is w.map[id]
      aaactive = c1.id;
    }
  }
  if ($('.SectionList').length === 1) {
    let sss = null;
    create_section_index(ns);
    let l;
    let ref1;
    for (i = l = 0, ref1 = segments.length; (0 <= ref1 ? l < ref1 : l > ref1); i = 0 <= ref1 ? ++l : --l) {
      c1 = segments[i];
      let ss = that.index_sections_by_segment_id[c1.id];
      if (ss) {
        sss = ss;
      }
      c1.section = sss;
      if (ss && ss.end === c1.id) {
        sss = null;
      }
    }
  }
  add_source_audio_collision(that.waveform.docid);
  w.update_underlines = true;
  w.set_active_transcript_line(aaactive, true);
  console.log('HERE');
  console.log(aactive);
  console.log(that.index2);
  active = aactive;
}

function create_section_index(ns){
  const that = ns;
  const w = ns.waveform;
  const begmap = {};
  const endmap = {};
  ns.index_sections_by_segment_id = {};
  ns.index_sections_by_name = {};
  return $('.SectionListItem').each(function(i, x) {
    var a, b, id, s, section;
    section = $(x).find(".Section").data().value.value;
    a = $(x).find('.BegSeg').data().value.value;
    b = $(x).find('.EndSeg').data().value.value;
    if (a && b && a === b) {
      id = w.rmap.get(`node-${a}`);
      s = {
        name: section,
        beg: id,
        end: id,
        list_item_id: $(x).data().meta.id
      };
      that.index_sections_by_segment_id[id] = s;
      return that.index_sections_by_name[section] = s;
    } else {
      if (a) {
        id = w.rmap.get(`node-${a}`);
        s = {
          name: section,
          beg: id,
          list_item_id: $(x).data().meta.id
        };
        that.index_sections_by_segment_id[id] = s;
        that.index_sections_by_name[section] = s;
      }
      if (b) {
        id = w.rmap.get(`node-${b}`);
        s = that.index_sections_by_name[section];
        s.end = id;
        return that.index_sections_by_segment_id[id] = s;
      }
    }
  });
}

function set_speaker(hh){
  const id = window.gdata(`#node-${hh.iid} .Speaker`).meta.id;
  const kb = new Keyboard('speakers');
  const h = {
    constraint: 'speakers',
    new_label: 'new speaker',
    getf: () => get_new_speaker(id, hh),
    setf: (value) => set_speaker_value(id, value),
    sel: '.Speaker',
    title: 'Speakers',
    help_screen: hh.help_screen,
    input_screen: hh.input_screen
  };
  kb.open_menu(h);
}

function set_speaker_value(id, value) {
  window.ldc.vars.last_speaker_used = value;
  ldc_annotate.add_message(id, 'change', { value: value });
  ldc_annotate.submit_form();
  ldc_annotate.add_callback( () => update_segments() );
}

function delete_segments(ids){
  for(let id of ids) ldc_annotate.add_message(id, 'delete', null);
  ldc_annotate.submit_form();
  ldc_annotate.add_callback( () => update_segments() );
}

function get_new_speaker(id, hh){
  const kb = new Keyboard('speaker');
  const h = {
    keyboard: kb,
    setf: (value) => set_speaker_value(id, value),
    title: 'type speaker, hit enter'
  };
  hh.input_screen.open_helper(h);
}



function open_section(h){
  if(ldc_nodes.get_constraint('section_order_forced') === true){
    section_order_forced_open(h);
  }
  else {
    open_section2(h);
  }
}

function section_order_forced_open(h){
  const obj = last_section_obj(h.iid, null);
  const length = obj.length;
  const a = obj.a;
  const b = obj.b;
  if(a > b){
    alert(`new section must follow last section, but ${a} > ${b}`);
    return;
  }
  const sections = ldc_nodes.get_constraint('sections');
  if(!sections){
      alert("sections aren't available");
      return;
  }
  if(length > sections.length){
    alert('no more sections');
    return;
  }
  add_section(sections[length], h.iid);
}

function open_sectionf(id, section){
  const obj = last_section_obj(id, section);
  if(!obj) return;
  if(obj.exists){
    alert(`section ${section} already exists`);
  }
  else if(obj.repeat){
    alert("sections can't overlap");
  }
  else{
    add_section(section, id);
  }
};

function open_section2(hh){
  const sections = document.getElementsByClassName('SectionListItem');
  console.log(`${sections.length} sections`);
  const kb = new Keyboard('sections');
  const h = {
    constraint: 'sections',
    new_label: 'new section',
    getf: () => get_new_section(hh),
    setf: (value) => open_sectionf(hh.iid, value),
    sel: '.Section',
    title: 'Sections',
    help_screen: hh.help_screen,
    input_screen: hh.input_screen
  };
  kb.open_menu(h);
}

function add_section(section, id){
  ldc_annotate.add_message(window.gdata('.SectionList').meta.id, 'add', null);
  ldc_annotate.add_message('new.Section', 'change', { value: section });
  ldc_annotate.add_message('new.BegSeg', 'change', { value: id });
  ldc_annotate.submit_form();
  ldc_annotate.add_callback( () => update_segments() );
}

function last_section_obj(id, current_section){
  const length = document.getElementsByClassName('SectionListItem').length;
  const h = {
    id: id,
    current_section: current_section,
    length: length,
    exists: false,
    repeat: false,
    overlap: false
  };
  if(length > 0){
    const nodeb = window.gdata(`#node-${id} .Segment`);
    if(current_section === null){
      h.src = null;
    }
    else{
      h.src = {
        beg: nodeb.value.beg,
        end: nodeb.value.end
      };
    }
    const last_section = find_last_section(h);
    if($(last_section).find('.EndSeg.empty').length === 1){
      alert('last section is still open');
      return;
    }
    const seg = $(last_section).find('.EndSeg').data().value.value;
    const nodea = window.gdata(`#node-${seg} .Segment`);
    if(nodea) h.a = nodea.value.end;
    if(nodeb) h.b = nodeb.value.beg;
  }
  return h;
}

function get_new_section(hh){
  const kb = new Keyboard('speaker');
  const h = {
    keyboard: kb,
    setf: (value) => add_section(value, hh.iid),
    title: 'type section, hit enter'
  };
  hh.input_screen.open_helper(h);
}

function close_section(h) {
  if(ldc_nodes.get_constraint('section_order_forced') === true){
    section_order_forced_close(h);
  }
  else{
    close_section2(h);
  }
}

function section_order_forced_close(hh){
  const h = get_open_section(hh.iid);
  if(h && h.id) set_pointer(h.eseg.meta.id, h.id);
}

function close_section2(hh) {
  const h = get_open_section(hh.iid);
  if(h){
    if(h.same){
      if(h.id){
        set_pointer(h.eseg.meta.id, h.id);
      }
    }
    else{
      h.overlap = false;
      h.src = {
        beg: h.a.value.beg,
        end: h.b.value.end
      };
      const last_section = find_last_section(h);
      if(h.overlap) alert("sections can't overlap");
      else if(h.id) set_pointer(h.eseg.meta.id, h.id);
    }
  }
}

function set_pointer(pointer, segment) {
  ldc_annotate.add_message(pointer, 'change', { value: segment });
  ldc_annotate.submit_form();
  ldc_annotate.add_callback( () => update_segments() );
}

function get_open_section(id){
  const h = { id: id };
  const length = document.getElementsByClassName('SectionListItem').length;
  let last_section = null;
  const segs = document.getElementsByClassName('EndSeg empty');
  if (segs.length === 0) {
    alert('no open sections');
    return;
  }
  const iid = segs[0].parentNode.id.split('-')[1];
  h.eseg = window.gdata(`#node-${iid} .EndSeg`)
  h.current_section = window.gdata(`#node-${iid} .Section`).value.value;
  h.bseg = window.gdata(`#node-${iid} .BegSeg`);
  const seg = h.bseg.value.value;
  if(seg !== id){
    h.a = window.gdata(`#node-${seg} .Segment`);
    h.a.value.beg = h.a.value.beg;
    h.b = window.gdata(`#node-${id} .Segment`);
    // alert "#{a} #{b}"
    if(h.a.value.end > h.b.value.beg){
      h.id = null;
      alert(`closing segment must follow opening segment, but ${h.a.value.end} > ${h.b.value.beg}`);
      return;
    }
  }
  else{
    h.same = true;
  }
  return h;
}

function find_last_section(h) {
  const src = h.src;
  let last = null;
  let last_section = null;
  $('.SectionListItem').each(function(i, x) {
    let iid = $(x).data().meta.id;
    if(Number(iid) > Number(last)){
      last = iid;
      last_section = x;
    }
    if($(x).find('.Section').data().value.value === h.current_section){
      h.exists = true;
    }
    else{
      if(src && src.beg && src.end) {
        let begseg = get_begendseg(x, '.BegSeg', h);
        let endseg = get_begendseg(x, '.EndSeg', h);
        if(begseg && endseg){
          if(begseg <= src.end && endseg >= src.beg || h.repeat) h.overlap = true;
        }
      }
    }
  });
  return last_section;
}

function get_begendseg(x, sel, h){
  let begseg = $(x).find(sel).data();
  if(begseg){
    begseg = begseg.value.value;
    if(begseg){
      if(begseg === h.id){
        h.repeat = true;
      }
      else{
        begseg = $(`#node-${begseg} .Segment`).data();
        if(begseg){
          // alert JSON.stringify begseg.value
          if(sel === '.BegSeg') begseg = begseg.value.beg;
          else                  begseg = begseg.value.end;
        }
      }
    }
  }
  return begseg;
}

export {
  update_segments,
  update_segments2,
  delete_segments,
  set_speaker,
  open_section,
  close_section
}
