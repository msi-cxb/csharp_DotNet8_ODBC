.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_json_virtual_columns
-- Description: JSON virtual columns - slow json_extract vs fast indexed virtual columns
-- Source: sqlite_json_virtual_columns in sqliteODBC_tests.vbs (line 2617)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_json_virtual_columns ===

CREATE TABLE events(value TEXT);

WITH RECURSIVE event(x) AS (
    SELECT 1 UNION ALL SELECT x+1 FROM event LIMIT 10000000
)
INSERT INTO events (value)
SELECT '{"timestamp":"2022-05-15T09:31:00Z","object":"user' || x || '","object_id":' || x || ',"action":"login","details":{"ip":"192.168.0.1"}}' FROM event;

-- RESULT:count(1)
-- RESULT:10000000
SELECT count(1) FROM events;

.print === slow queries using json_extract ===

-- RESULT:object,action,object_id
-- RESULT:user1000000,login,1000000
SELECT
    json_extract(value, '$.object') AS object,
    json_extract(value, '$.action') AS action,
    json_extract(value, '$.object_id') AS object_id
FROM events
WHERE json_extract(value, '$.object_id') = 1000000;

-- RESULT:object,action,object_id
-- RESULT:user5000000,login,5000000
SELECT
    json_extract(value, '$.object') AS object,
    json_extract(value, '$.action') AS action,
    json_extract(value, '$.object_id') AS object_id
FROM events
WHERE json_extract(value, '$.object_id') = 5000000;

-- RESULT:object,action,object_id
-- RESULT:user10000000,login,10000000
SELECT
    json_extract(value, '$.object') AS object,
    json_extract(value, '$.action') AS action,
    json_extract(value, '$.object_id') AS object_id
FROM events
WHERE json_extract(value, '$.object_id') = 10000000;

.print === add virtual columns and index ===

ALTER TABLE events ADD COLUMN object_id INTEGER AS (json_extract(value, '$.object_id'));
ALTER TABLE events ADD COLUMN object TEXT AS (json_extract(value, '$.object'));
ALTER TABLE events ADD COLUMN action TEXT AS (json_extract(value, '$.action'));
CREATE INDEX events_object_id ON events(object_id);

.print === fast queries using virtual columns ===

-- RESULT:object,action,object_id
-- RESULT:user1000000,login,1000000
SELECT object, action, object_id FROM events WHERE object_id = 1000000;

-- RESULT:object,action,object_id
-- RESULT:user5000000,login,5000000
SELECT object, action, object_id FROM events WHERE object_id = 5000000;

-- RESULT:object,action,object_id
-- RESULT:user10000000,login,10000000
SELECT object, action, object_id FROM events WHERE object_id = 10000000;

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
