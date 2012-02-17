
$.extends({

    // get or set lexer
    lexer : function (lexer) {
        if (!lexer) {
            return getGeneralProperty(_('SCI_GETLEXER'));
        } else {
            lexer = _('SCLEX', lexer);
          
            if (false !== lexer) {
                setGeneralProperty(_('SCI_SETLEXER'), lexer, 0);
            }
        }
    }
});

$.style('php', {
    comment     :   {fore : '#000000', back: '#ffffff', font: 'sd', size: 'sdf', bold: 1}
});

$.style;

$.defaults


$.style('.php .comment');

