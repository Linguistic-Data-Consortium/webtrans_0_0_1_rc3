const x = {
  Enter: 'set_active_transcript_line_to_next_and_play_current_span',
  Tab: 'keyboard_focus',
  // e.preventDefault()
  ArrowUp: 'set_active_transcript_line_to_prev',
  ArrowDown: 'set_active_transcript_line_to_next',
  control: {
    j: 'add_to',
    s: 'set_speaker',
    ' ': 'play_current_span',
    d: 'delete_active_transcript_line',
    ',': 'split_segment_at_cursor',
    m: 'merge_with_following_segment',
    '[': 'open_section',
    ']': 'close_section',
    // '\\': 'delete_last_section_confirm'
    '\\': 'show_sections',
    p: 'play_head_menu'
  }
};

export { x }
