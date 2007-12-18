function switch_formatter() {
    var selected_format = $('input[@name=formatter]:checked').val();
    if (selected_format == 'ubb') {
        $('.ubb').show();
    } else {
        $('.ubb').hide();
    }
}
$(document).ready(function() {
    switch_formatter();
} );