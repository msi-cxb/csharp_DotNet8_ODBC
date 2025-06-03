.timer on
.echo on

.print sqlite

-- table with day that validates entry
create or replace table d (
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
