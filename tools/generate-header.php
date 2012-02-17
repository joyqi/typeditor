<?php

function read_define($file, $filter) {
    $lines = file($file);
    $result = array();
    echo "+{$file}\n";

    foreach ($lines as $line) {
        $line = trim($line);

        if (0 === strpos($line, '#define ')) {
            $parts = preg_split("/\s/s", $line);

            if (count($parts) > 2) {
                $result[] = $filter($parts[1], $parts[2]);
                echo "-{$parts[1]}\n";
            }
        }
    }

    return $result;
}

function camel_str($str) {
    return lcfirst(str_replace(' ', '', ucwords(implode(' ', explode('_', strtolower($str))))));
}

// parse SciLexer.h
$result = read_define('../scintilla/include/SciLexer.h', function ($key, $val) {
    $parts = explode('_', $key, 2);
    
    switch ($parts[0]) {
        case 'SCLEX':
            return array('lexer.' . strtolower($parts[1]), $val);
        case 'SCE':
            $parts = explode('_', $parts[1], 2);
            return array('style.' . strtolower($parts[0]) . 
                '.' . camel_str($parts[1]), $val);
        default:
            return;
    }
});

foreach ($result as $val) {
    echo "{$val[0]}:{$val[1]}\n";
}

