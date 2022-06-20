var ldc_languages = {
	//this function is called when loading the index page
    init_index: function(){
	$('.display').dataTable(
      {paging: true,
        sAjaxSource: $('#languages').data('source')}
    );
    }
};

