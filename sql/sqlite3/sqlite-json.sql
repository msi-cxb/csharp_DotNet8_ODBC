.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_json
-- Description: JSON functions - json(), json_array(), -> operator
-- Source: sqlite_json in sqliteODBC_tests.vbs (line 2565)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_json ===

-- RESULT:j
-- RESULT:{"this":"is","a":["test"]}
SELECT json(' { "this" : "is", "a": [ "test" ] } ') as j;

-- RESULT:j
-- RESULT:[1,2,"3",4]
SELECT json_array(1,2,'3',4) as j;

-- RESULT:j
-- RESULT:["[1,2]"]
SELECT json_array('[1,2]') as j;

-- RESULT:j
-- RESULT:[[1,2]]
SELECT json_array(json_array(1,2)) as j;

-- RESULT:j
-- RESULT:[1,null,"3","[4,5]","{\"six\":7.7}"]
SELECT json_array(1,null,'3','[4,5]','{"six":7.7}') as j;

-- RESULT:j
-- RESULT:[1,null,"3",[4,5],{"six":7.7}]
SELECT json_array(1,null,'3',json('[4,5]'),json('{"six":7.7}')) as j;

-- RESULT:j
-- RESULT:[4,5,{"f":7}]
SELECT '{"a":2,"c":[4,5,{"f":7}]}' -> '$.c' as j;

INSERT INTO timer VALUES('file', 'the end', unixepoch('now', 'subsec'));

.print time results
SELECT
    task_name,
    note,
    strftime('%H:%M:%f', ts_msec_delta, 'unixepoch') AS delta
FROM (
    SELECT *,
        ts_msec - LAG(ts_msec, 1) OVER (PARTITION BY task_name ORDER BY ts_msec) AS ts_msec_delta
    FROM (SELECT *, row_number() OVER () AS rowid FROM timer)
) WHERE ts_msec_delta IS NOT NULL ORDER BY rowid;
