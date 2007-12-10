$(document.forms).each( function(theform) {
    
    // disabled the Submit and Reset when submit a form
    // to avoid duplicate submit
    $(theform).submit( function() {
        $('input:submit').attr( { disabled : 'disabled' } );
        $('input:reset').attr(  { disabled : 'disabled' } );
    } );
    
    // Press Ctrl+Enter to submit the form. like QQ.
    $(theform).keypress( function(evt) {
        var x = evt.keyCode;
        var q = evt.ctrlKey;
        
        if (q && (x == 13 || x == 10)) {
            theform.submit();
        }
    } );
} );