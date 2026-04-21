.echo on
-- .timer on
.conn duckdb

-- https://duckdb.org/docs/stable/sql/functions/overview

-- RESULT:duck_name
-- RESULT:African duck
-- RESULT:Faroese duck
-- RESULT:Hungarian duck
-- RESULT:Pomeranian duck
SELECT replace(goose_name, 'goose', 'duck') AS duck_name
FROM unnest(['African goose', 'Faroese goose', 'Hungarian goose', 'Pomeranian goose']) breed(goose_name);

-- RESULT:duck_name
-- RESULT:African duck
-- RESULT:Faroese duck
-- RESULT:Hungarian duck
-- RESULT:Pomeranian duck
SELECT goose_name.replace('goose', 'duck') AS duck_name
FROM unnest(['African goose', 'Faroese goose', 'Hungarian goose', 'Pomeranian goose']) breed(goose_name);

-- RESULT:"replace"('hello world', ' ', '_')
-- RESULT:hello_world
SELECT ('hello world').replace(' ', '_');

-- RESULT:sqrt(2)
-- RESULT:1.4142135623730951
SELECT (2).sqrt();

-- RESULT:map_entries(m[1])
-- RESULT:[{'key': hello, 'value': 42}]
SELECT (m[1]).map_entries()
FROM (VALUES ([MAP {'hello': 42}, MAP {'world': 42}])) t(m);

-- RESULT:function_name,function_type,return_type,parameters,parameter_types,description
-- RESULT:bar,scalar,VARCHAR,[x, min, max, width],[DOUBLE, DOUBLE, DOUBLE, DOUBLE],Draws a band whose width is proportional to (`x - min`) and equal to `width` characters when `x` = `max`. `width` defaults to 80.
-- RESULT:base64,scalar,VARCHAR,[blob],[BLOB],Converts a `blob` to a base64 encoded string.
-- RESULT:bin,scalar,VARCHAR,[string],[VARCHAR],Converts the `string` to binary representation.
-- RESULT:bit_count,scalar,TINYINT,[x],[TINYINT],Returns the number of bits that are set
-- RESULT:bit_length,scalar,BIGINT,[string],[VARCHAR],Number of bits in a `string`.
-- RESULT:bit_position,scalar,INTEGER,[substring, bitstring],[BIT, BIT],Returns first starting index of the specified substring within bits, or zero if it is not present. The first (leftmost) bit is indexed 1
-- RESULT:bitstring,scalar,BIT,[bitstring, length],[VARCHAR, INTEGER],Pads the bitstring until the specified length
SELECT DISTINCT ON(function_name)
    function_name,
    function_type,
    return_type,
    parameters,
    parameter_types,
    description
FROM duckdb_functions()
WHERE function_type = 'scalar'
  AND function_name LIKE 'b%'
ORDER BY function_name;

