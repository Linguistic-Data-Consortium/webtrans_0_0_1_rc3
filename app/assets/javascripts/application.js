// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= requiree rails-ujs
//= requiree dataTables/jquery.dataTables
//= requiree lui
//= requiree refills
//= requiree global
//= requiree autocomplete
//= requiree activestorage

jQuery(function() {
    setTimeout(function(){
        window.location.reload();
    }, 43200000);
    console.log("auto refresh in " + 43200000 + " ms");
});
