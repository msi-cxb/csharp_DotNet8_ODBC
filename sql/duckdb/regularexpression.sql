.echo on
-- .timer on
.conn duckdb

-- https://duckdb.org/docs/stable/sql/functions/regular_expressions.html

-- RESULT:regexp_matches('abc', 'abc')
-- RESULT:true
SELECT regexp_matches('abc', 'abc');
-- RESULT:regexp_matches('abc', '^abc$')
-- RESULT:true
SELECT regexp_matches('abc', '^abc$');
-- RESULT:regexp_matches('abc', 'a')
-- RESULT:true
SELECT regexp_matches('abc', 'a');
-- RESULT:regexp_matches('abc', '^a$')
-- RESULT:false
SELECT regexp_matches('abc', '^a$');
-- RESULT:regexp_matches('abc', '.*(b|d).*')
-- RESULT:true
SELECT regexp_matches('abc', '.*(b|d).*');
-- RESULT:regexp_matches('abc', '(b|c).*')
-- RESULT:true
SELECT regexp_matches('abc', '(b|c).*');
-- RESULT:regexp_matches('abc', '^(b|c).*')
-- RESULT:false
SELECT regexp_matches('abc', '^(b|c).*');
-- RESULT:regexp_matches('abc', '(?i)A')
-- RESULT:true
SELECT regexp_matches('abc', '(?i)A');
-- RESULT:regexp_matches('abc', 'A', 'i')
-- RESULT:true
SELECT regexp_matches('abc', 'A', 'i');
-- RESULT:regexp_matches('abcd', 'ABC', 'c')
-- RESULT:false
SELECT regexp_matches('abcd', 'ABC', 'c');
-- RESULT:regexp_matches('abcd', 'ABC', 'i')
-- RESULT:true
SELECT regexp_matches('abcd', 'ABC', 'i');
-- RESULT:regexp_matches('ab^/$cd', '^/$', 'l')
-- RESULT:true
SELECT regexp_matches('ab^/$cd', '^/$', 'l');

-- these generate result with carriage return so can't compare
-- this this implementation of C# program
SELECT regexp_matches(E'hello\nworld', 'hello.world', 'p');
SELECT regexp_matches(E'hello\nworld', 'hello.world', 's');

-- RESULT:regexp_replace('abc', '(b|c)', 'X')
-- RESULT:aXc
SELECT regexp_replace('abc', '(b|c)', 'X');
-- RESULT:regexp_replace('abc', '(b|c)', 'X', 'g')
-- RESULT:aXX
SELECT regexp_replace('abc', '(b|c)', 'X', 'g');
-- RESULT:regexp_replace('abc', '(b|c)', '\1\1\1\1')
-- RESULT:abbbbc
SELECT regexp_replace('abc', '(b|c)', '\1\1\1\1');
-- RESULT:regexp_replace('abc', '(.*)c', '\1e')
-- RESULT:abe
SELECT regexp_replace('abc', '(.*)c', '\1e');
-- RESULT:regexp_replace('abc', '(a)(b)', '\2\1')
-- RESULT:bac
SELECT regexp_replace('abc', '(a)(b)', '\2\1');
-- RESULT:regexp_extract('abc', '.b.')
-- RESULT:abc
SELECT regexp_extract('abc', '.b.');
-- RESULT:regexp_extract('abc', '.b.', 0)
-- RESULT:abc
SELECT regexp_extract('abc', '.b.', 0);
-- RESULT:regexp_extract('abc', '.b.', 1)
-- RESULT:
SELECT regexp_extract('abc', '.b.', 1);
-- RESULT:regexp_extract('abc', '([a-z])(b)', 1)
-- RESULT:a
SELECT regexp_extract('abc', '([a-z])(b)', 1);
-- RESULT:regexp_extract('abc', '([a-z])(b)', 2)
-- RESULT:b
SELECT regexp_extract('abc', '([a-z])(b)', 2);
-- RESULT:regexp_extract('2023-04-15', '(\d+)-(\d+)-(\d+)', main.list_value('y', 'm', 'd'))
-- RESULT:{'y': 2023, 'm': 04, 'd': 15}
SELECT regexp_extract('2023-04-15', '(\d+)-(\d+)-(\d+)', ['y', 'm', 'd']);
-- RESULT:regexp_extract('2023-04-15 07:59:56', '^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)', main.list_value('y', 'm', 'd'))
-- RESULT:{'y': 2023, 'm': 04, 'd': 15}
SELECT regexp_extract('2023-04-15 07:59:56', '^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)', ['y', 'm', 'd']);



