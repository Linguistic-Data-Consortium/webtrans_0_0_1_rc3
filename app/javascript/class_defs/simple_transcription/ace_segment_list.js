// Generated by CoffeeScript 2.6.1
var SegmentList;

import 'ace-builds';

import "ace-builds/webpack-resolver";

SegmentList = class SegmentList {
  constructor(node, data1, ns) {
    var callback, that, vars;
    this.node = node;
    this.data = data1;
    this.ns = ns;
    vars = window.ldc.vars;
    this.sel1 = `.${vars.add_from_waveform_list}Item`;
    this.sel2 = `.${vars.add_from_waveform_audio}`;
    this.sel3 = `.${vars.add_from_waveform_text}`;
    this.sel4 = ".Speaker";
    vars.experimental = $('.Root').data().obj.task_preferences.x === 'x';
    this.x = vars.experimental;
    this.x = window.location.href.match(/ace/);
    if (this.x) {
      this.use_ace();
    }
    this.edit = false;
    this.timer = null;
    this.cursor = {
      row: null,
      column: null
    };
    that = this;
    this.line_count = null;
    callback = function() {
      return $('.SegmentListItem').each(function(i, x) {
        var b, data, e, id, rmap, v;
        data = $(x).data();
        id = data.meta.id;
        v = $(x).find('.Transcription').data().value.value;
        rmap = that.ns.waveform.rmap;
        e = $('#editor').data();
        e = e.editor;
        if (rmap && e) {
          id = rmap[`node-${id}`];
          if (id && that.index3) {
            id = that.index3[id];
            if (id || id === 0) {
              b = e.session.getDocument().getLine(id) === v;
            }
          }
        }
        return console.log(`checking ${id} ${b}`);
      });
    };
  }

  // setInterval callback, 1000
  logic() {
    var active, line_count, that;
    that = this;
    that.ns.segment_list_f('segments', that);
    if (that.x) {
      $('.SegmentListItem, .segments').hide();
      line_count = $('.SegmentListItem').length;
      if (line_count !== this.line_count) {
        that.block_change_cursor = true;
        this.line_count = line_count;
        this.editor.setValue(this.editor_value);
        this.editor.selection.clearSelection();
        if (that.set_active) {
          active = that.ns.waveform.rmap[that.set_active];
          that.set_active = null;
          that.ns.waveform.set_active_transcript_line(active, true);
          that.editor.gotoLine(that.index3[active] + 1);
        }
        return that.block_change_cursor = false;
      }
    }
  }

  set_active_transcript_line(row) {
    var id, that, w, x;
    that = this;
    console.log('indexes');
    console.log(that.data.index);
    console.log(that.index2);
    console.log(that.index3);
    // row = that.editor.getCursorPosition().row
    x = that.index2[row];
    if (x) {
      id = x.id;
      w = that.ns.waveform;
      w.set_mode_to_cursor();
      return w.set_active_transcript_line(id);
    }
  }

  use_ace() {
    var editor, fixnum, that;
    that = this;
    $('.Root').append('<div id="editor"/>');
    $('#editor').before('<div id=autosave></div>');
    this.initial_editor_value = "var hello = 'world'\nthis\n   that\n   blah";
    editor = ace.edit('editor', {
      maxLines: 10,
      minLines: 10,
      value: this.initial_editor_value
    });
    // mode: "ace/mode/javascript"
    this.editor = editor;
    $('#editor').data().editor = editor;
    editor.commands.bindKey("Tab", function() {
      var row;
      row = that.cursor.row;
      if (row || row === 0) {
        that.save_row(row);
      }
      return $('.keyboard').focus();
    });
    editor.commands.bindKey("Shift-Enter|Ctrl-Backspace|Shift-Backspace|Backspace|Ctrl-H", function() {
      return console.log('noop');
    });
    editor.commands.bindKey("Enter", function() {
      that.editor.gotoLine(that.cursor.row + 2);
      return that.ns.waveform.play_current_span();
    });
    editor.commands.bindKey("Control-Space", function() {
      return that.ns.waveform.play_current_span();
    });
    editor.commands.bindKey("Control-J", function() {
      return that.add_to();
    });
    editor.commands.bindKey("Control-S", function() {
      return that.ns.waveform.set_speaker();
    });
    editor.commands.bindKey("Control-D", function() {
      $('.keyboard').focus();
      that.cursor.row = null;
      return that.ns.waveform.delete_active_transcript_line();
    });
    editor.commands.bindKey("Control-,", function() {
      var active;
      active = $('.active-transcript-line').attr('id');
      that.set_active = that.ns.waveform.map[active];
      return that.ns.waveform.split_segment_at_cursor();
    });
    editor.commands.bindKey("Control-M", function() {
      var active;
      active = $('.active-transcript-line').attr('id');
      that.set_active = that.ns.waveform.map[active];
      return that.ns.waveform.merge_with_following_segment();
    });
    editor.commands.bindKey("Control-F", function() {
      return that.ns.set_section();
    });
    $('.Root').on('click', '#editor', function() {
      if ($('.SegmentListItem').length === 1 && $('.crnt').length === 0) {
        return that.set_active_transcript_line(0);
      }
    });
    // editor.commands.addCommand
    //     name: 'update'
    //     bindkey: { mac: 'Enter' }
    //     exec: (editor) ->
    //         console.log 'update'
    editor.commands.addCommand({
      name: 'indent',
      bindkey: null,
      exec: null
    });
    editor.commands.addCommand({
      name: 'outdent',
      bindkey: null,
      exec: null
    });
    // editor = ace.edit("editor")
    // editor.setTheme("ace/theme/monokai")
    // editor.session.setMode("ace/mode/javascript")
    fixnum = function(n) {
      var a, b, c;
      n = `${n}`.padStart(7);
      a = `${n}`.split(".");
      b = a[0].padStart(7);
      c = a[1] ? a[1].padEnd(3, "0") : '000';
      return `${b}.${c}`;
    };
    editor.session.gutterRenderer = {
      getWidth: function(session, lastLineNumber, config) {
        // lastLineNumber.toString().length * config.characterWidth;
        return 300;
      },
      getText: function(session, row) {
        var a, aa, b, bb, c, cc, dd;
        c = that.index2[`${row}`];
        if (c) {
          a = fixnum(c.beg);
          b = fixnum(c.end);
        } else {
          a = fixnum("0.0");
          b = fixnum("0.");
        }
        aa = `${row + 1}`.padStart(3);
        bb = a;
        cc = b;
        dd = c ? `${c.speaker}`.padStart(10) : '';
        return `${aa} ${bb} ${cc} ${dd}`;
      }
    };
    editor.selection.on('changeCursor', function(e) {
      var p, row;
      if (that.block_change_cursor) {
        return;
      }
      console.log("change");
      console.log(e);
      p = that.editor.getCursorPosition();
      row = that.cursor.row;
      that.cursor = p;
      if (p.row === row) {
        console.log('noop');
      } else {
        if (row || row === 0) {
          that.save_row(row);
        }
      }
      return that.set_active_transcript_line(p.row);
    });
    return editor.selection.on('blur', function(e) {
      var p, row;
      if (that.block_change_cursor) {
        return;
      }
      console.log("change");
      console.log(e);
      p = that.editor.getCursorPosition();
      row = that.cursor.row;
      that.cursor = p;
      if (row || row === 0) {
        that.save_row(row);
      }
      return that.set_active_transcript_line(p.row);
    });
  }

  set_playing_transcript_line(found) {
    var i, j, ref, that;
    that = this;
    for (i = j = 0, ref = $('.ace_gutter-cell').length; (0 <= ref ? j < ref : j > ref); i = 0 <= ref ? ++j : --j) {
      that.editor.session.removeGutterDecoration(i, 'green');
    }
    return that.editor.session.addGutterDecoration(that.index3[found], 'green');
  }

  add_to() {
    var y;
    y = '{blurb}';
    return this.editor.insert(y);
  }

  autosave() {
    var that;
    that = this;
    if (that.timer) {
      clearTimeout(that.timer);
    }
    $('#autosave').text('will autosave');
    return that.timer = setTimeout(function() {
      $('#autosave').text('autosaving');
      setTimeout(function() {
        return $('#autosave').text('');
      }, 3000);
      return that.save_row();
    }, 10000);
  }

  // if e.end
  //     row = e.end.row
  //     console.log "changing row #{row}"
  //     # range = new ace.Range(0, 0, 1, 1)
  //     # console.log editor.session.getTextRange range
  //     line = editor.session.getDocument().getLine(row)
  //     console.log line
  save_row(row) {
    var h, that;
    that = this;
    h = that.save_row_check(row);
    if (h.line !== h.value) {
      console.log(`CHANGE ${h.id} from ${h.value} to ${h.line}`);
      return ldc_nodes.add_message_submit(h.id, 'change', {
        value: h.line
      });
    } else {
      return console.log("NO CHANGE");
    }
  }

  save_row_check(row) {
    var h, iid, line, t, that;
    that = this;
    // row = that.editor.getCursorPosition().row
    line = that.editor.session.getDocument().getLine(row);
    console.log(row);
    iid = that.index2[row].iid;
    t = $(`#node-${iid} .Transcription`).data();
    h = {
      line: line,
      value: t.value.value,
      id: t.meta.id
    };
    return h;
  }

  focus_segment(x) {
    var row, that;
    that = this;
    if (that.x) {
      that.editor.focus();
      row = x ? that.index3[x] : 0;
      if (row !== this.cursor.row) {
        return that.editor.gotoLine(row + 1);
      }
    }
  }

};

export {
  SegmentList
};