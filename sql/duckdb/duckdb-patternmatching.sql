.echo on
-- .timer on
.conn duckdb

-- https://duckdb.org/docs/stable/sql/functions/pattern_matching

-- RESULT:('abc' ~~ 'abc')
-- RESULT:true
SELECT 'abc' LIKE 'abc';

-- RESULT:('abc' ~~ 'a%')
-- RESULT:true
SELECT 'abc' LIKE 'a%' ;

-- RESULT:('abc' ~~ '_b_')
-- RESULT:true
SELECT 'abc' LIKE '_b_';

-- RESULT:('abc' ~~ 'c')
-- RESULT:false
SELECT 'abc' LIKE 'c';

-- RESULT:('abc' ~~ 'c%')
-- RESULT:false
SELECT 'abc' LIKE 'c%';

-- RESULT:('abc' ~~ '%c')
-- RESULT:true
SELECT 'abc' LIKE '%c';

-- RESULT:('abc' !~~ '%c')
-- RESULT:false
SELECT 'abc' NOT LIKE '%c';

-- RESULT:('abc' ~~* '%C')
-- RESULT:true
SELECT 'abc' ILIKE '%C'; 

-- RESULT:('abc' !~~* '%C')
-- RESULT:false
SELECT 'abc' NOT ILIKE '%C'; 

-- RESULT:main.like_escape('a%c', 'a$%c', '$')
-- RESULT:true
SELECT 'a%c' LIKE 'a$%c' ESCAPE '$';

-- RESULT:main.like_escape('azc', 'a$%c', '$')
-- RESULT:false
SELECT 'azc' LIKE 'a$%c' ESCAPE '$';

-- RESULT:main.ilike_escape('A%c', 'a$%c', '$')
-- RESULT:true
SELECT 'A%c' ILIKE 'a$%c' ESCAPE '$';

-- RESULT:regexp_full_match('abc', 'abc')
-- RESULT:true
SELECT 'abc' SIMILAR TO 'abc';

-- RESULT:regexp_full_match('abc', 'a')
-- RESULT:false
SELECT 'abc' SIMILAR TO 'a';

-- RESULT:regexp_full_match('abc', '.*(b|d).*')
-- RESULT:true
SELECT 'abc' SIMILAR TO '.*(b|d).*';

-- RESULT:regexp_full_match('abc', '(b|c).*')
-- RESULT:false
SELECT 'abc' SIMILAR TO '(b|c).*';

-- RESULT:(NOT regexp_full_match('abc', 'abc'))
-- RESULT:false
SELECT 'abc' NOT SIMILAR TO 'abc';

-- RESULT:('best.txt' ~~~ '*.txt')
-- RESULT:true
SELECT 'best.txt' GLOB '*.txt';

-- RESULT:('best.txt' ~~~ '????.txt')
-- RESULT:true
SELECT 'best.txt' GLOB '????.txt';

-- RESULT:('best.txt' ~~~ '?.txt')
-- RESULT:false
SELECT 'best.txt' GLOB '?.txt';

-- RESULT:('best.txt' ~~~ '[abc]est.txt')
-- RESULT:true
SELECT 'best.txt' GLOB '[abc]est.txt';

-- RESULT:('best.txt' ~~~ '[a-z]est.txt')
-- RESULT:true
SELECT 'best.txt' GLOB '[a-z]est.txt';

-- RESULT:('Best.txt' ~~~ '[a-z]est.txt')
-- RESULT:false
SELECT 'Best.txt' GLOB '[a-z]est.txt';

-- RESULT:('Best.txt' ~~~ '[a-zA-Z]est.txt')
-- RESULT:true
SELECT 'Best.txt' GLOB '[a-zA-Z]est.txt';

-- RESULT:('Best.txt' ~~~ '[!a-zA-Z]est.txt')
-- RESULT:false
SELECT 'Best.txt' GLOB '[!a-zA-Z]est.txt';

-- RESULT:(NOT ('best.txt' ~~~ '*.txt'))
-- RESULT:false
SELECT NOT 'best.txt' GLOB '*.txt';

SELECT * FROM glob('**/csharp_DotNet8_ODBC.exe');