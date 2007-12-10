function star(obj_type, obj_id, obj_div) {
    var url = '/ajax/star';
    var pars = 'obj_type=' + obj_type + '&obj_id=' + obj_id;
    star_obj_div = obj_div;

    $.get('/ajax/star', { 'obj_type': obj_type, 'obj_id': obj_id }, function(data) {
        if (data == 1) {
            $('#' + star_obj_div).html('<img src="http://mail.google.com/mail/images/star_on_2.gif" />');
        } else {
            $('#' + star_obj_div).html('<img src="http://mail.google.com/mail/images/star_off_2.gif" />');
        }
    } );
}
