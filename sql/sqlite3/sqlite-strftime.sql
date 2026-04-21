.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_strftime
-- Description: strftime() extended format specifiers - %G %g %U %V %e %F %I %k %l %p %P %R %T %u
-- Source: sqlite_strftime in sqliteODBC_tests.vbs (line 2551)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_strftime ===

-- RESULT:r
-- RESULT: 7 -- 2013-10-07 -- 08 --  8 --  8 -- AM -- am -- 08:23 -- 08:23:19 -- 1 -- 2013 -- 13 -- 40 -- 41
SELECT strftime('%e -- %F -- %I -- %k -- %l -- %p -- %P -- %R -- %T -- %u -- %G -- %g -- %U -- %V', '2013-10-07T08:23:19.120') AS r;

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
