$(document).ready(function() {
    $.get('/ajax/new_message', function(data) {
        $('#new_message').html(data);
    } );
} );