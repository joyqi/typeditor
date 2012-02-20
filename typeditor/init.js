$.lexer(function (str) {
    var pos = str.indexOf('select');
        if (pos >= 0) {
            $.replace(pos, 3, 'fasfa');
            // $.style(pos, 6);
        }
});