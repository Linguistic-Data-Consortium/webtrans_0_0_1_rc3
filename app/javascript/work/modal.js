// Generated by CoffeeScript 2.6.1
var Modal;

Modal = class Modal {
  constructor(h) {
    var k, v;
    for (k in h) {
      v = h[k];
      this[k] = v;
    }
  }

  init() {
    var that;
    that = this;
    $('.ann_pane').append(ldc_nodes.array2html([
      'div',
      'id',
      that.name,
      'class',
      'modal',
      [
        [
          // [ 'label', 'for', 'done_comment_modal_state', [
          //     [ 'div', 'class', 'modal-trigger', 'Comment' ]
          // ] ]
          'div',
          'class',
          'modal-fade-screen',
          [
            [
              'div',
              'class',
              'modal-inner',
              [
                ['div',
                'class',
                'modal-close',
                ''],
                ['h3',
                that.h],
                ['div',
                'class',
                'modal-body',
                []],
                [
                  // [ 'input', 'id', 'done_comment', 'style', 'width: 100%', 'type', 'text', '' ]
                  'div',
                  'class',
                  'flex',
                  [
                    ['button',
                    'class',
                    'ok',
                    'modal',
                    that.b],
                    // [ 'button', 'class', 'none', 'modal', 'NONE' ]
                    ['button',
                    'class',
                    'cancel',
                    'modal',
                    'Cancel']
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]));
    $(`#${that.name}`).on('click', '.ok', function() {
      that.delegate[that.f]();
      return that.close_modal();
    });
    return $(`#${that.name}`).on('click', '.cancel', function() {
      return that.close_modal();
    });
  }

  open_modal() {
    $(`#${this.name}`).addClass('open');
    return $("body").addClass("modal-open");
  }

  close_modal() {
    $(`#${this.name}`).removeClass('open');
    return $("body").removeClass("modal-open");
  }

};

export {
  Modal
};
