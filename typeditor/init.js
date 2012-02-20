$.lexer(function (str) {
    var pos = str.indexOf('select');
        if (pos >= 0) {
            $.style(pos, 6);
        }
});