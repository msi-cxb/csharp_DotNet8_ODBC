-- .echo on
-- .timer on
.conn sqlite3

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
insert into timer values('file','the start',unixepoch('now','subsec'));

-- RESULT:vers,srcId
-- RESULT:3.50.3,2025-07-17 13:25:10 3ce993b8657d6d9deda380a93cdd6404a8c8ba1b185b2bc423703e41ae5f2543
SELECT sqlite_version() as vers, sqlite_source_id() as srcId;

insert into timer values('file','the end',unixepoch('now','subsec'));

.print time results
select 
    task_name,
    note,
    strftime('%H:%M:%f', ts_msec_delta, 'unixepoch') as delta
from
(
    SELECT 
        *,
        ts_msec - LAG(ts_msec, 1) OVER (PARTITION BY task_name ORDER BY ts_msec) AS ts_msec_delta
    FROM (
        SELECT *, row_number() over () as rowid FROM timer
    )
) where ts_msec_delta IS NOT NULL order by rowid;

