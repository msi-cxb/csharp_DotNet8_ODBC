-- https://duckdb.org/2025/09/11/solving-letter-scramble-puzzles.html

.echo on
-- .timer on
.conn duckdb

.print DuckDB version string
-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.0,b8a06e4a22,Andium
PRAGMA version;

-- note that comments are removed from this query as they break parsing 
CREATE MACRO order_letters(s) AS 
    lower(s)
    .regexp_replace(
        '[^\p{L}]', '', 'g'
    )
    .string_to_array('') 
    .list_distinct() 
    .list_sort();

-- RESULT:letters_1,letters_2,letters_3,matches_1,matches_2
-- RESULT:[a, d, e, m, r, s, t],[a, d, e, m, r, s, t],[a, d, e, m, r, s, t],true,true
SELECT
    order_letters('Amsterdam') AS letters_1,
    order_letters('mastered') AS letters_2,
    order_letters('Dream Master') AS letters_3,
    letters_1 = letters_2 AS matches_1,
    letters_1 = letters_3 AS matches_2;

CREATE TABLE stations AS
    FROM 'https://blobs.duckdb.org/nl-railway/stations-2023-09.csv';

-- RESULT:cnt
-- RESULT:591
SELECT COUNT(1) as cnt FROM stations;

-- RESULT:name_long
-- RESULT:Lelystad Centrum
SELECT name_long
FROM stations
WHERE order_letters(name_long) = order_letters('Clumsy Rental Red');

CREATE MACRO find_weak_anagram(s) AS TABLE
    SELECT name_long
    FROM stations
    WHERE order_letters(name_long) = order_letters(s);

-- RESULT:name_long
-- RESULT:Lelystad Centrum
FROM find_weak_anagram('Clumsy Rental Red');

-- again removed comments from inside of query as they break parsing
-- RESULT:station_1,station_2
-- RESULT:Melsele,Selm
-- RESULT:Etten-Leur,Lunteren
-- RESULT:Diemen Zuid,Emmen Zuid
SELECT s1.name_long AS station_1, s2.name_long AS station_2
FROM stations s1, stations s2
WHERE s1.name_long.order_letters() = s2.name_long.order_letters()
    AND s1.name_long < s2.name_long
    AND NOT s1.name_long.contains(s2.name_long)
    AND NOT s2.name_long.contains(s1.name_long);

DROP MACRO order_letters;
DROP MACRO TABLE find_weak_anagram;








