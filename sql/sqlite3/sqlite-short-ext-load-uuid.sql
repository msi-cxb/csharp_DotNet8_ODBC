.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_extension_uuid (MEM segment)
-- Description: uuid extension - uuid(), uuid_str(), uuid_blob() via load_extension
-- Source: sqlite_extension_uuid in sqliteODBC_tests.vbs (line 1630)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_uuid MEM load_extension ===

-- Note: load_extension throws error but works
-- Note: expected to fail with: Function sequence error
SELECT load_extension('%APPDATA%\sqlite\64bit\uuid.dll') AS ext_loaded;

-- Note: expects 1 row
SELECT uuid() AS uv4;

.print === uuid_str and uuid_blob variants ===

-- RESULT:us,ub
-- RESULT:a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11,X'A0EEBC999C0B4EF8BB6D6BB9BD380A11'
SELECT uuid_str('A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11') AS us, uuid_blob('A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11') AS ub;

-- RESULT:us,ub
-- RESULT:a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11,X'A0EEBC999C0B4EF8BB6D6BB9BD380A11'
SELECT uuid_str('{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}') AS us, uuid_blob('{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}') AS ub;

-- RESULT:us,ub
-- RESULT:a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11,X'A0EEBC999C0B4EF8BB6D6BB9BD380A11'
SELECT uuid_str('a0eebc999c0b4ef8bb6d6bb9bd380a11') AS us, uuid_blob('a0eebc999c0b4ef8bb6d6bb9bd380a11') AS ub;

-- RESULT:us,ub
-- RESULT:a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11,X'A0EEBC999C0B4EF8BB6D6BB9BD380A11'
SELECT uuid_str('a0ee-bc99-9c0b-4ef8-bb6d-6bb9-bd38-0a11') AS us, uuid_blob('a0ee-bc99-9c0b-4ef8-bb6d-6bb9-bd38-0a11') AS ub;

-- RESULT:us,ub
-- RESULT:a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11,X'A0EEBC999C0B4EF8BB6D6BB9BD380A11'
SELECT uuid_str('{a0eebc99-9c0b4ef8-bb6d6bb9-bd380a11') AS us, uuid_blob('{a0eebc99-9c0b4ef8-bb6d6bb9-bd380a11') AS ub;

-- RESULT:us,ub
-- RESULT:a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11,X'A0EEBC999C0B4EF8BB6D6BB9BD380A11'
SELECT uuid_str('{a0eebc99-9c0b4ef8-bb6d6bb9-bd380a11}') AS us, uuid_blob('{a0eebc99-9c0b4ef8-bb6d6bb9-bd380a11}') AS ub;

-- RESULT:us,ub
-- RESULT:a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11,X'A0EEBC999C0B4EF8BB6D6BB9BD380A11'
SELECT uuid_str('A0EEBC99-9C0B4EF8-BB6D-6BB9BD380A11') AS us, uuid_blob('A0EEBC99-9C0B4EF8-BB6D-6BB9BD380A11') AS ub;

-- RESULT:us,ub
-- RESULT:null,null
SELECT uuid_str('0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11') AS us, uuid_blob('0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11') AS ub;

-- RESULT:us,ub
-- RESULT:a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11,X'A0EEBC999C0B4EF8BB6D6BB9BD380A11'
SELECT uuid_str('{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11') AS us, uuid_blob('{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11') AS ub;

-- RESULT:us,ub
-- RESULT:null,null
SELECT uuid_str('a0eebc999c0b4ef8bb6d6bb9bd380a1') AS us, uuid_blob('a0eebc999c0b4ef8bb6d6bb9bd380a1') AS ub;

-- RESULT:us,ub
-- RESULT:null,null
SELECT uuid_str('a0ee-bc99-9c0b-4ef8-bb6d-6bb9-a11') AS us, uuid_blob('a0ee-bc99-9c0b-4ef8-bb6d-6bb9-a11') AS ub;

-- RESULT:us,ub
-- RESULT:null,null
SELECT uuid_str('{a0eebc{99-9c0b4ef8-bb6d6bb9-bd380a11}') AS us, uuid_blob('{a0eebc{99-9c0b4ef8-bb6d6bb9-bd380a11}') AS ub;

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
