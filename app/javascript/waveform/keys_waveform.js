const x = {
  cursor: {
    // Tab: 'set_active_transcript_line_to_last_created'
    Tab: 'focus_input',
    ' ': 'play_current_span_or_play_stop',
    Enter: 'add_transcript_line_and_activate',
    '/': 'add_transcript_line_based_on_play_head',
    // when 109 # m
    '0': 'open_spectrogram',
    z: 'toggle_zoom',
    i: 'zoom_in',
    o: 'zoom_out',
    // p: 'sort_then_split'
    p: 'play_head_menu',
    r: 'refresh_waveform',
    // s: 'sort_transcript_lines_forward'
    // q: 'service_help_menu'
    q: 'settings',
    h: 'show_help_screen_main',
    // a: 'show_all_transcript_lines'
    '@': 'not_sure',
    '`': 'play_current_span',
    // '1': 'add_sad'
    // '2': 'get_alignment'
    D: 'delete_all_confirm',
    // j: 'move_cursor_left_big'
    // k: 'move_cursor_right_big'
    // l: 'move_cursor_left_little'
    // ';': 'move_cursor_right_little'
    w: 'set_mode_to_window',
    b: 'set_mode_to_beg',
    e: 'set_mode_to_end',
    f: 'move_cursor_lstep1',
    d: 'move_cursor_lstep2',
    s: 'move_cursor_lstep3',
    a: 'move_cursor_lstep4',
    j: 'move_cursor_rstep1',
    k: 'move_cursor_rstep2',
    l: 'move_cursor_rstep3',
    ';': 'move_cursor_rstep4',
    // x: 'mouse_swipe'
    x: 'speaker_test',
    ',': 'split_segment_at_cursor',
    m: 'merge_with_following_segment',
    'ArrowUp': 'set_active_transcript_line_to_prev',
    'ArrowDown': 'set_active_transcript_line_to_next',
    n: 'set_active_transcript_line_to_next',
    u: 'upload_transcript'
  },
  window: {
    c: 'set_mode_to_cursor',
    b: 'set_mode_to_beg',
    e: 'set_mode_to_end',
    f: 'move_window_lstep1',
    d: 'move_window_lstep2',
    s: 'move_window_lstep3',
    a: 'move_window_lstep4',
    j: 'move_window_rstep1',
    k: 'move_window_rstep2',
    l: 'move_window_rstep3',
    ';': 'move_window_rstep4'
  },
  selection: {
    c: 'set_mode_to_cursor',
    w: 'set_mode_to_window',
    b: 'set_mode_to_beg',
    e: 'set_mode_to_end',
    f: 'move_selection_lstep1',
    d: 'move_selection_lstep2',
    s: 'move_selection_lstep3',
    a: 'move_selection_lstep4',
    j: 'move_selection_rstep1',
    k: 'move_selection_rstep2',
    l: 'move_selection_rstep3',
    ';': 'move_selection_rstep4'
  },
  control: {
    cursor: {
      Enter: 'play_current_span_and_add_transcript_line_and_activate',
      i: 'info',
      s: 'spectrogram'
    }
  }
};

export { x }
