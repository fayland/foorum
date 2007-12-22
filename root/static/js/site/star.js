function star(obj_type, obj_id, obj_div) {
    $.get('/ajax/star', { 'obj_type': obj_type, 'obj_id': obj_id }, function(data) {
        if (data == 1) {
            $('#' + obj_div).html('<img src="http://mail.google.com/mail/images/star_on_2.gif" />');
        } else {
            $('#' + obj_div).html('<img src="http://mail.google.com/mail/images/star_off_2.gif" />');
        }
    } );
}

function share(obj_type, obj_id, obj_div) {
    $.get('/ajax/share', { 'obj_type': obj_type, 'obj_id': obj_id }, function(data) {
        if (data == 1) {
            $('#' + obj_div).html('Unshare');
        } else {
            $('#' + obj_div).html('Share');
        }
    } );
}