var $ = {
    
    // find defined constants
    _ : function () {
        var args = [];

        for (var i = 0; i < arguments.length; i ++) {
            args.push(arguments[i].toUpperCase());
        }
    
        var value = _[args.join('_')];
        return 'undefined' == typeof(value) ? false : value;
    },

    // get or set lexer
    lexer : function (lexer) {
        if (!lexer) {
            return editor.getGeneralProperty($._('SCI_GETLEXER'));
        } else {
            lexer = $._('SCLEX', lexer);
          
            if (false !== lexer) {
                editor.setGeneralProperty($._('SCI_SETLEXER'), lexer, 0);
            }
        }
    },

    // log to console
    log : function () {
        var str = arguments[0], args = arguments, pos = 0;

        editor.log(str.replace(/%@/g, function (holder) {
            pos ++;
            return args[pos] ? args[pos] : holder;
        }));
    }
};

