$(document).ready(function() {    
    $.get('/ajax/new_message', function(data) {
        $('#new_message').html(data);
    } );
} );

/*
function new_message() {
    
    var url = '/ajax/new_message';
    var pars = '';

    var myAjax = new Ajax.Request( url, {
	    method: 'get',
	    parameters: pars,
	    onSuccess: show_message
	} );
}

function show_message(request) {
    response  = request.responseText;
    if (response != '') {
        Element.update('new_message', response);
    } else {
        window.setTimeout("new_message();", 60000);
    }
}

Event.observe(window, 'load', new_message, false);
*/