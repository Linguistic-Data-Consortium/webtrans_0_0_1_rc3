var ldc = {};
var ldc_annotate = function(){

    window.ldc.vars = {}

    var global_object;
    var kit_id;
    var task_user_id;
    var task_id;
    var quality_control = false;
    var messages = []; // message(s) to send to the annotate controller
    var submissions = {}; // messages sent
    var curdocid = '';
    var curtextsource = null; // current TextSource node
    var nodes = {}; // maps ids to nodes in tree
    var constraints = {}; // constraints on trees
    var audio_finished = {}; //tracks whether an audio widget has finished playing
    var audio_playing = {}; //tracks whether an audio widget is currently playing
    var workflow = null;
    var embedded_lists = {};
    var submittable_classes = '.Radio, .Menu, .MultiMenu, .CheckboxGroup, .Checkbox, .SLeaf, .Textarea, .Entry, .ButtonGroupRadio, .Set';
    var readonly = false;
    var text_capture = false;//tracks whether we are in text capture mode
    var has_coref_refdoc = false;//tracks whether the tool has a coref reference document
    //var changing_list_item = false;//tracks whether a change submission is happening on a ListItem, since ListItem's cannot be independently detected
    var submission_canceled = false;//tracks whether we need to cancel the next submission of annotation data
    var debug = false; // when true changes behavior to help testing
    var separate_document_window = null;
    var div2node = function(sel){ return nodes[$(sel).attr('id').replace('node-', '')] };
    var div2sel = function(div){ return '#' + div.id };
    var jsons = function(obj) { return JSON.stringify(obj) };
    var jsonsp = function(obj) {
        $.each(nodes, function(x, y){
            delete y.meta.parent;
        });
        return JSON.stringify(obj)
    };

    // var source_transform = false;//tracks whether we are transforming text for newly loaded documents or not
    var source_transform = null;
    var arabic_text = false; // tracks whether the text is in Arabic; ldc_source.show_source treat the text differently if yes
    var source_sentence_transform = null;
    var override_text_limit = false;
    var time_spent = null; // tracks the time in seconds the annotator spent on the kit
    var track_time_spent = false; // wether or not to track time_spent on the kit
    var sentence_segmenter  = null; // the segmenter TextMethods::SentenceSegmenters::transform_sentences uses
    var annotations_promise = Promise.resolve();

    // this is where the ldc_annotate object gets created and returned
    return {

      //this function sets whether time_spent mode is on
        set_track_time_spent: function(st){
            track_time_spent = st;
        },

        // get the current time_spent
        // this is different from get_time_spent, which get time_spent
        // from the server
        cur_time_spent: function(){
            return time_spent;
        },

        //this function adds a message to the queue for annotation
        add_message: function(n, m, v){
            if(m == 'add'){
                // console.log('aaaaaaaaaaaaa')
                // console.log(n)
                // console.log(nodes[n])
                // console.log(ldc_nodes.get_node_class(nodes[n].meta.node_class_id))
                v = nodes[n].meta.node_class_id;
            }
            messages.push( { node: n, message: m, value: v } );
        },

        show_submissions: function(){
            console.log(submissions);
        },

        //this function removes the last element in the messages array, and returns it. if the messages array is empty, it returns null
        remove_message: function(){
            return messages.length > 0 ? messages.pop() : null;
        },

        //this function cancels the next submit for annotation
        cancel_submission: function(){
            submission_canceled = true;
        },

        // for checking the validity of messages and nodes
        check_messages: function(){
          that = this;
            //return true;
            error = "error";
            if(messages.length == 0){
                return true;
            }
            else{
                m = messages[0];
                if(m.node == '0' && (m.message.match(/^done/))){
                    invalid = false;
                    label = '';
                    //a = [ constraints.invalid[1] ]
                    if(constraints.invalid){
                        //if(ldc_nodes.check_or( { or: constraints.invalid } )){
                        if(ldc_nodes.match_pattern('.Root', constraints.invalid, false)){
                            $('#error_modal').modal();
                            return false;
                        }
                    }
                }
                else{
                    //$('#confirm_dialog').html(jsonsp(nodes['0'].meta.types)).dialog('option', 'title', 'Error');
                    /*$('#confirm_dialog').html(jsonsp(m)).dialog('option', 'title', 'Error');
                    $('#confirm_dialog').data('ok', function(){
                        window.location.reload();
                    }).dialog('open');*/
                }
                if(debug){
                    return false;
                }
                return true;
            }
        },

        delay: function(f){
            var that = this;
            if(messages.length > 0){
                console.log('delay messages');
                setTimeout( function(){ that.delay(f) }, 1000 );
            }
            else{
                f();
            }
        },

        submit_form: function(){
            var m = [];
            m = messages.slice();
            messages = [];
            annotations_promise = annotations_promise.then( function(){
                return ldc_annotate.submit_form_old(m);
            });
        },

        add_callback: function(f){
            annotations_promise = annotations_promise.then(f);
        },

        //this is the function which actually submits annotations to the annotate action in the annotate controller
        submit_form_old: function(m){
            var messages = m;
            var promise = Promise.resolve();
            console.log( 'SUBMIT' )
            if(false && messages[0].node == '0'){ // for debugging
                console.log(this.check_messages())
                submission_canceled = false; // just in case this was set
                messages = [];
            }
            else if(!this.check_messages()){
            //else if(this.check_messages()){
                submission_canceled = false; // just in case this was set
                messages = [];
            }
            else{
                //when the submission canceled flag is set: skip form submission code, reset the submission canceled flag, clear the messages array
                if(submission_canceled){
                    submission_canceled = false;
                    messages = [];
                }else{
                    var that = this;
                    var obj = {};
                    obj.messages = messages;
                    d = new Date();
                    obj.client_time = d.getTime();
                    obj.kit_uid = $('.Root').data().obj._id
                    if(messages.length > 0){
                    // if(task_id == 351){
                        // ldc_nodes.check_pending(submissions);
                        if(readonly){
                            var mmessage = 'read only, json request would have been: ' + JSON.stringify(obj);
                            this.message_modal(mmessage);
                        }
                        else{
                            var url = '/annotations';
                            if(quality_control){
                                url += '?qc=true&kit_id=' + kit_id;
                            }
                            submissions[obj.client_time] = obj
                            that.pending_save_before(messages);
                            promise = ldc_nodes.post(url, { task_user_id: task_user_id, json: JSON.stringify(obj) }, function(data){ console.time('annotate2'); that.annotate2(data, obj.client_time); console.timeEnd('annotate2'); });
                            obj.received = false;
                            submissions[obj.client_time] = obj;
                        }
                        // ldc_nodes.check_pending(submissions);
                        messages = [];
                    }
                }
            }
            return promise;
        },

//test: function(){ return nodes },
        // iterates down through a tree, adding the nodes to the "nodes" index
        add_nodes: function(node, parent) {
            var that = this;
            var n = node.meta.id;
            nodes[n] = node;
            node.meta.parent = parent;

//            alert(jsonsp(node.meta))
            if(node.children){
                $.each(node.children, function(x,y){
                    that.add_nodes(node.meta.list ? y : node[y], node);//list children need special handling
                });
            }
        },

        //this function changes the font color for text with the provided offsets
        color_text_from_offsets: function (source, beg, end, color, namestring, count) {
            if(count){
                //swaps the begin and end variables if they are reversed
                if( beg > end ) { var tmp = beg; beg = end; end = tmp; }

                for( var i = beg; i <= end; i++ ){
                    $(source + '-char' + i).css('color', color);
                    $(source + '-char' + i).attr('title', namestring + ' appears ' + count + ' times in the corpus');
                }
            }
        },

        /*
         * this function takes in a string of form: source1-char### and returns the integer ###, which is an offset,
         * so it only works for inputs of that format
         */
        get_offset: function(id){
            return parseInt(id.match(/(\d+)/g)[1]);
        },

        /*
         * this function takes in a string of form: source1-char### and returns the prefix string before the ###,
         * the prefix string can then be used to append ### sequences to
         */
        get_offset_prefix: function(id){
            var x = null;
            x = '#' + id.replace(/char-(\d+)/, 'char-');
            return x.replace('##', '#');
        },

        get_override_text_limit: function(){
            return override_text_limit;
        },

        set_override_text_limit: function(x){
            override_text_limit = x;
        },

        //this function updates the current doc to an existing doc, based on the doc id
        set_current_doc_from_id: function(id){
            curdocid = id;
        },

        //this function sets the current document based on the source data
        set_current_doc: function(data){
            curdocid = data.id;
        },

        annotate2: function(messages, client_time){
            console.log(client_time);
            submissions[client_time].received = true;
            if(messages.error){
                ldc_lui.display_alert('error', messages.error);
                if(messages.full_error) console.log(messages.full_error);
                return;
            }
            var that = this;
            console.log("ANN2")
            console.log(messages)
            $.each(messages, function(i, hash){
                console.log('getting message');
                console.log(hash);
                ldc_nodes.confirm_message(hash);
                if(hash.hasOwnProperty('noop')){
                    return;
                }
                if(hash.hasOwnProperty('error')){
                    if(hash.error === 'This tree is locked.'){
                        $('#tree_locked_modal').addClass('open');
                        $("body").addClass("modal-open");
                        if(hash.current){
                            $('#current_locked').show()
                        }
                        else{
                            $('#current_locked').hide()
                        }
                    }
                    else{
                        $('#message_dialog').html(hash.error).dialog('option', 'title', 'Error').dialog('open');
                    }
                    return;
                }
                if(hash.hasOwnProperty('redirect')){
                    if(hash.message === 'cant_play'){
                        $('.ann_pane').html('We have marked that you could not play your last call. Click <a href="' + hash.redirect + '">here</a> or refresh to get another call');
                        return;
                    }
                    else if(hash.message === 'inactive'){
                        $('.ann_pane').html('<h1>This tasks is inactive, redirecting.</h1>')
                        setTimeout( function(){
                            window.location.href = hash.redirect;
                        }, 3000);
                        return;
                    }
                    else{
                        $('.ann_pane').html('');
                        window.location.href = hash.redirect;
                        return;
                    }
                }
                if(hash.message === 'add'){
                    return;
                    // if(nodes[hash.old_id].meta.extra_classes && nodes[hash.old_id].meta.extra_classes.match(/List-mode-1/)){
                    //     $('#node-' + hash.old_id).children('.icon-plus').before(hash.html);
                    // }
                    // else{
                    //     console.log(nodes[hash.old_id].meta.extra_classes)
                    //      $('#node-' + hash.old_id).prepend(hash.html);
                    // }
                    // that.add_nodes(hash.new_node);
                    // nodes[hash.old_id].children.push(hash.new_node);
                    // hash.new_node.meta.parent = nodes[hash.old_id];
                    // hash.new_node.added = true;
                    // ldc_nodes.init_node2(hash.new_node, nodes[hash.old_id], '#node-' + hash.old_id);
                    // that.refresh_node(hash.new_node.meta.id);
                    // //if updates specific to the workflow are needed, pass back the list item selector
                    // if(workflow.hasOwnProperty('update_after_add_node')){
                    //     workflow['update_after_add_node']('#node-' + hash.new_node.meta.id);
                    // }
                    // ldc_logic.logic($('#node-' + hash.new_node.meta.id).data());
                    // // $.each(messages, function(i, m){
                    // //     if(m.message == 'change'){
                    // //         that.pending_save_change(m.old_id, m.node.value);
                    // //     }
                    // // });
                    // $('#node-' + hash.old_id + '-dummy').remove();
                }
                else if(hash.message === 'change'){
                }
                else if(hash.message === 'delete'){
                    var children = nodes[hash.parent_id].children;
                    // children.splice(children.indexOf(nodes[hash.old_id]), 1);
                    // $('#node-' + hash.old_id + '-dummy').remove();

                    // //if updates specific to the workflow are needed, pass back the list selector
                    // if(workflow.hasOwnProperty('update_after_delete_node')){
                    //     workflow['update_after_delete_node']('#node-' + hash.parent_id);
                    // }
                    // ldc_logic.logic($('#node-' + hash.parent_id).data());
                }
            });
            // ldc_nodes.after_annotate(messages, workflow, global_object);
        },

        initt: function(kit){
            console.log(kit)
            if(kit.refresh == true){
              t = 3;
              setInterval(function(){
                  if(t == 0){
                    window.location.reload();
                  }
                  else {
                    $('body').html("restarting in " + String(t) + " seconds");
                    t -= 1;
                  }
              }, 1000);
              return;
            }
            that = this
            ldc_nodes.nodes = nodes
            if(kit.read_only == true){
                url = '/kits/get?uid=' + kit._id + '&task_user_id=readonly';
            }
            else{
                url = '/kits/get?uid=' + kit._id + '&task_user_id=' + kit.task_user_id;
            }
            url += '&mode=two'
            setInterval(function(){
                ldc_nodes.check_pending(submissions);
            }, 1000);
            console.log("HERE")
            console.log(that)
            $('.ann_pane').html('<div class="Root" id="node-0"></div>');
            ldc_nodes.initt_ajax(
                kit, url
            ).then(that.init).then(that.init_view).then(
                // basic init code that I wanted to keep in ldc_nodes
                function(x){
                    ldc_nodes.initg();
                    ldc_nodes.init();
                }
            )
        },

        //main initialization function called from the view
        init: function(obj) {
            // setTimeout(function(){
            //     window.location.href = '/';
            // }, 5000);
            console.log("THERE")
            console.log(this)
            that = ldc_annotate;
            // $('#trouble').on('click', function(){
            //     that.trouble({ uid: obj._id });
            // });
            console.log(obj)
            global_object = obj;
            task_id = obj.task_id;
            constraints = obj.constraints;
            ldc_nodes.set_constraints(constraints);

            ldc_nodes.set_node_classes2(obj);
            ldc_nodes.set_node_classes_url(false);

            // $('.Root').data().skip_refresh = $('.ann_pane').data().skip_refresh
            // $('.Root').data().resources = $('.ann_pane').data().resources
            // 
            // window.ldc.resources = $('.ann_pane').data().resources
            if(obj._id){
                kit_id = obj._id;
                $('#kit_message').html('Kit number: ' + kit_id);
            }
            readonly = obj.read_only;
            //readonly = true;
            quality_control = obj.quality_control;
            if(obj.task_user_id){
                task_user_id = obj.task_user_id;
            }

            /* code for tracking time spent on the kit
               the setInterval call checks if there are
               activities every 30s; if yes, then increase time spent
               by 30s, otherwise do nothing;
               */
            window.activity_detected = false;

            $(document).on('mousemove click keydown', function(e){
              window.activity_detected = true;
            });

            // get time_spent from the server
            that.get_time_spent({"uid": kit_id});

            // if track_time_spent is set to true
            // check and increase timer every 30 seconds
            // change_time_spent writes the new time_spent to
            // the sever
            setInterval(function(){
                var purchase = {
                    time: 30,
                    kit_uid: kit_id,
                    task_id: task_id,
                  referrer: document.referrer,
                  keen: {
                    timestamp: new Date().toISOString()
                  }
                };

              if(track_time_spent && time_spent != null && window.activity_detected){
                  time_spent += 30;
                  that.change_time_spent({"uid": kit_id, "time_spent": time_spent})
                  window.activity_detected = false;
                // Send it to the "purchases" collection
                    purchase.spent = true;
                    // client.addEvent("purchases", purchase);
                }
                else{
                    purchase.spent = false;
                    // Send it to the "purchases" collection
                    // client.addEvent("purchases", purchase);
                }
              }, 30000);

            // END of time_spent code

            // setInterval(function(){
            //     $.get('/user_defined_objects/20', function(response){
                //  console.log(response)
            //     }, 'json');
            //  console.log('hello')
            // } , 3000);


            //set this value for multi document kits
            if(obj.source_transform) source_transform = obj.source_transform;
            if(obj.source && obj.source.transform) source_transform = obj.source.transform;
            //alert(jsons(obj.source));

        //     $.get('/nodes/15254821', function(response){
        //         $('.ann_pane').html(JSON.stringify(response))
        //         that.init2(obj);
        //     }, 'json');
        // },

        // init2: function(obj){
            //$.get('/nodes', 'kit_uid='+obj._id, function(data){ $('.ann_pane').append(data.html) }, "json" );
            console.log(9)
            ldc_annotate.add_nodes(obj.tree, null);

            return obj;
        },

        /*
         * last function to get called on initialization, runs the workflow specific page open code,
         * adds submission listeners, and loads any dialogs
         */
        init_view: function(obj){
            that = ldc_annotate;
            $('.Root').data().obj = obj;
            obj.workflow = workflow;
            ldc_nodes.workflow_open();
        },
        
        close_kit: function(){
            if(separate_document_window){
                separate_document_window.close();
            }
            if(workflow.hasOwnProperty('finished_check')){
                workflow['finished_check']('done');
            }
            $('#close_comment_modal').addClass('open');
            $("body").addClass("modal-open");
            var done_comment = $('.Root').data().obj.done_comment;
            var uid = $('.Root').data().obj.source.uid;
            var uid = $('.Root').data().obj.filename;
            if(done_comment){
              v = done_comment;
            }
            else{
              v = uid;
            }
            $('#close_comment').val(v);
        },

        open_separate_document_window: function(selector){
            $(selector).hide();
            separate_document_window = window.open('', "webann_document_window", "toolbar=no,menubar=no,status=no,width=750,height=500");
            // separate_document_window.document.write($(selector).html())
        },
        open_separate_document_window2: function(selector){
            // separate_document_window = window.open('', "_blank", "toolbar=no,menubar=no,status=no,width=750,height=500");
            separate_document_window.document.open();
            separate_document_window.document.write('<style> .addedp { margin: 10px; } </style>');
            separate_document_window.document.write('<div class="Document Node"><p>')
            separate_document_window.document.write($(selector).html());
            separate_document_window.document.write('</p></div>');
            separate_document_window.document.close();
        },

        //get a specific node based on its text key
        get_node: function(text){
            return nodes[text];
        },
        get_nodes: function(){
            return nodes;
        },

        //get a specific node value based on its selector
        get_node_value: function(selector){
            var node_id = ldc_lui.getNodeId(selector);
            if(node_id){
                var node = this.get_node(node_id)
                if(node){
                    return node.value;
                }
            }
        },

        pending_save_before: function(messages){
            that = this;
            console.log('pending_save_before');
            console.log(messages);
            $.each(messages, function(i, m){
                console.log(i);
                console.log(m);
                if(m.message == 'change'){
                    selector = '#node-' + m.node;
                    ldc_nodes.pending_save_change(m);
                }
                if(m.message == 'add'){
                    ldc_nodes.pending_save_add(m);
                }
                if(m.message == 'delete'){
                    ldc_nodes.pending_save_delete(m);
                }
                ldc_nodes.save_message(m);
            });
            ldc_nodes.after_annotate(messages, workflow, global_object);
        },

        // pending_save_change: function(n, value){
        //     selector = '#node-' + n;
        //     $(selector).data().value = value;
        //     $(selector).data().meta.user = global_object.user_id;
        //     $(selector).data().meta.task = global_object.task_id;
        //     nodes[n].value = value;
        //     nodes[n].meta.user = global_object.user_id;
        //     nodes[n].meta.task = global_object.task_id;
        //     if(workflow.hasOwnProperty('update_after_change_node')){
        //         workflow['update_after_change_node'](selector);
        //     }
        // },

        // pending_save_after: function(n){
        //     selector = '#node-' + n;
        //     $(selector).find('.control-group').removeClass('error');
        //     $(selector).find('.control-group select').prop('disabled', false);
        // },

        // mainly for applying css, but ok for anything that can be applied multiple times to the same node safely.  see the init_node method above.

        refresh_node2: function(n){
            var node = '#node-' + n;


            // console.log('refreshing ' + n)
            var types = nodes[n].meta.types;

            //add any extra classes as defined in style manager
            // if(nodes[n].meta.extra_classes) $(node).addClass(nodes[n].meta.extra_classes);
            // ldc_nodes.refresh_node(types, nodes[n], true, node);
            var that = this;
            if(nodes[n].children){
                $.each(nodes[n].children, function(x,y) {
                    var c;
                    if($.inArray('List', types) != -1){
                        c = y;
                    }
                    else{
                        c = nodes[n][y];
                        that.refresh_node2(c.meta.id);
                    }
                    // that.refresh_node2(c.meta.id);
                });
            }
        },

        //function to highlight/unhighlight given element
        highlight_element: function (element, highlight) {
            if(highlight){
                element.attr("highlighted", "highlighted").css("background-color", "red");
            }
            else {
                element.removeAttr("highlighted").css("background-color", "");
            }
        },

        //function to select/deselect given element
        select_element: function(element, select) {
            if(select){
                element.attr("selected", "selected").css("opacity", ".3");
            }
            else {
                element.removeAttr("selected").css("opacity", "");
            }
        },

        /* maintain a list pointer
         * ensures list.beg and list.end are in chronological order, rather than list.beg < list.end
         * furthermore, list.beg and list.end can be anything, not just integers
         * however, list.beg != list.end */
        update_list: function(n, index){
            var list = $('#node-' + n).data().meta.selection;
            if(list.end == null){
                if(list.beg == null){
                    list.beg = index;
                }
                else if(list.beg == index){
                    list.beg = null;
                }
                else{
                    list.end = index;
                }
            }
            else{
                list.beg = null;
                list.end = null;
            }
        },

        /*
         * this function sends a static button post search, used by the Next/Previous search buttons
         */
        button_search: function (params) {
            $.post('/search/query', params, function(response){
                $('#' + response['pane']).html(response['results_html']);
            }, 'json');
        },

        /* this function sets time_spent variable to the value on the server
          this function should be called once when a kit is loaded for annotation
          */
        get_time_spent: function (params) {
          $.post('/kits/get_time_spent', params, function(response){
            t = parseInt(response['message']);
            time_spent = isNaN(t)?0:t;
          });
        },

        change_time_spent: function (params) {
          $.post('/kits/change_time_spent', params, function(response){});
        },

        trouble: function (params) {
          $.get('/kits/trouble', params, function(response){
            if(response.type === 'success'){
                $('#trouble').replaceWith('<li>reported</li>');
            }
            else{
                $('#trouble').replacdeWith('<li>failed</li>');
            }
          });
        },

        //this function sets the sentence segmenter TextMethods::SentenceSegmenters::transform_sentences
        set_sentence_segmenter: function(st){
          sentence_segmenter = st;
        },

        //this function returns the sentence_segmenter TextMethods::SentenceSegmenters::transform_sentences
        get_sentence_segmenter: function(){
          return sentence_segmenter;
        },

        /*
         * this function sets the changing list item value
         */
        //set_changing_list_item: function(value){
          //  changing_list_item = value;
        //},

        //this function returns the currently highlighted text in a TextSource node
        get_highlighted_text: function(){
            return $('#node-' + curtextsource).data().meta.selection;
        },

        //this function sets the current TextSource widget, used for annotation and underlining
        set_curtextsource: function(n){
            curtextsource = n;
        },

        //this function gets the current TextSource widget, used for annotation and underlining
        get_curtextsource: function(){
            return curtextsource;
        },

        //this function returns true / false whether text is selected
        // really is is_text_not_selected
        // reverse the name or polarity on this at some point
        is_text_selected: function(){
            return curtextsource === null || $('#node-' + curtextsource).data().meta.selection.beg === null;
        },

        //this function returns a text widget value from the current selection
        get_value_from_current_selection: function(){
            return this.get_value_from_specific_selection(curtextsource);
            // return {docid: ldc_source.get_current_docid(), beg: this.get_offset(lists[curtextsource].beg),
            //  end: this.get_offset(lists[curtextsource].end), text: lists[curtextsource].text,
            //  message_id: lists[curtextsource].message_id};
        },

        //this function submits a form, presuming we're on the admin annotation page
        admin_submit_form: function(){
            alert('This feature is currently broken, sorry.');
            /*
            task_user_id = $('#task_user_id').val();
            kit_id = $('#kit_id').val();
            received_object = {read_only: false};
            quality_control = true;
            var original_val = $('#node_value').val();
            var value = original_val.charAt(0) === '{' ? $.parseJSON(original_val) : original_val;
            this.add_message($('#node_id').val(), $('#node_message').val(), value);
            this.submit_form();*/
        },
        count_selected_mentions: function(){
            $('#selected-mention-count').text('selected mentions: ' + $('.selected-mention').length);
        },

        //this function gets passed into the click listener for an add list item button
        add_list_item_to_list: function(list_selector){
            var listId = ldc_lui.getNodeId($(list_selector));
            this.add_message(listId, 'add', null);
        }

    }; //corresponds to return
}();
