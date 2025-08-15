-- .timer on
-- .echo on
.conn sqlite3

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
insert into timer values('file','the start',unixepoch('now','subsec'));

-- table with day that validates entry
drop table if exists d;
create table d (
  day   date not null check (strftime('%F', unixepoch(day), 'unixepoch') = day)
);

insert into d values ('2025-02-28');
insert into d values ('2025-02-29');
insert into d values ('2024-02-29');

delete from d;

insert into d(day)
WITH dates AS (
    SELECT DATE(JULIANDAY('2024-01-01')) as Date,1 as Period
    UNION
    SELECT DATE(JULIANDAY(Date)+1) as date, Period+1 FROM dates WHERE DATE(JULIANDAY(Date)+1) <= DATE(JULIANDAY('2025-12-31'))
)SELECT date FROM dates ORDER BY Date;

-- output first and last day of each month
-- note 2024 is a leap year so last day of Feb is 2024-02-29
-- RESULT:firstOfMonth,lastOfMonth
-- RESULT:20240101120000,2024-01-31
-- RESULT:20240201120000,2024-02-29
-- RESULT:20240301120000,2024-03-31
-- RESULT:20240401120000,2024-04-30
-- RESULT:20240501120000,2024-05-31
-- RESULT:20240601120000,2024-06-30
-- RESULT:20240701120000,2024-07-31
-- RESULT:20240801120000,2024-08-31
-- RESULT:20240901120000,2024-09-30
-- RESULT:20241001120000,2024-10-31
-- RESULT:20241101120000,2024-11-30
-- RESULT:20241201120000,2024-12-31
-- RESULT:20250101120000,2025-01-31
-- RESULT:20250201120000,2025-02-28
-- RESULT:20250301120000,2025-03-31
-- RESULT:20250401120000,2025-04-30
-- RESULT:20250501120000,2025-05-31
-- RESULT:20250601120000,2025-06-30
-- RESULT:20250701120000,2025-07-31
-- RESULT:20250801120000,2025-08-31
-- RESULT:20250901120000,2025-09-30
-- RESULT:20251001120000,2025-10-31
-- RESULT:20251101120000,2025-11-30
-- RESULT:20251201120000,2025-12-31
select day as firstOfMonth,date(day,'start of month','+1 month','-1 day') as lastOfMonth from d where strftime('%d', day) = '01';

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

