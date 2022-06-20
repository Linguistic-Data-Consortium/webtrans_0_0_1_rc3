// Generated by CoffeeScript 2.6.1
var Section, last_speaker_used, setspeakerf;

import {
  Keyboard
} from '../../work/keyboard';

last_speaker_used = null;


Section = class Section {
  constructor(ns) {
    this.ns = ns;
  }

  get_last_speaker_used() {
    return last_speaker_used;
  }


  set_section() {
    var h, kb, that, w;
    that = this;
    w = this.ns.waveform;
    kb = new Keyboard('sections');
    // short = kb.shortcuts()
    // map = {}
    // speakerm = {}
    // spkrs = ldc_nodes.get_constraint('sections')
    // if spkrs
    //     speakers = []
    //     if spkrs.substr(0,4) is 'new,'
    //         speakers = [ [ 'n', 'new section' ] ]
    //         map.n = 'get_new_section'
    //         w[map.n] = -> that.get_new_section()
    //         spkrs = spkrs.substr(4)
    //     $.each spkrs.split(','), (i, x) ->
    //         speakerm[x] = short[i]
    // else
    //     speakers = [ [ 'n', 'new section' ] ]
    //     map.n = 'get_new_section'
    //     w[map.n] = -> that.get_new_section()
    //     $('.Section').each (i, y) ->
    //         x = $(y).data().value.value
    //         if x and not speakerm[x]
    //             speakerm[x] = short[i]
    // i = 0
    // $.each speakerm, (x, cc) ->
    //     c = short[i]
    //     i += 1
    //     speakers.push [ c, x ]
    //     map[c] = "set_section_#{c}"
    //     w[map[c]] = -> setspeakerf that, x
    // kb.set_map map
    // kb.set_delegate w
    h = {
      obj: that,
      w: w,
      constraint: 'sections',
      new_label: 'new section',
      get_name: 'get_new_section',
      set_name: 'set_section',
      setf: setsectionf,
      sel: '.Section',
      title: 'Sections'
    };
    // kb.show_mini_screen w, true
    return $('.ann_pane').data().help_screen.open(h);
  }

};

export {
  Section
};