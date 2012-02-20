$.lexer(function (str) {
    var pos = str.indexOf('select');
        if (pos >= 0) {
            // $.replace(pos, 3, 'fasfa');
            $.style(pos, 6);
        
        $.style(pos, 6, {
                'background-color' : '#fff'
        });
        }
});

$.keyup(function (key, pos, str) {
        $.autocomplete([], function (item, index) {
            
        });
});

$.keyup(function () {
    
});