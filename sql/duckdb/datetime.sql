.timer on
.echo on

.print duckdb

-- table with day that validates entry
create or replace table d ( day   DATE not null );

insert into d values ('2025-02-28');
insert into d values ('2025-02-29');
insert into d values ('2024-02-29');

delete from d;

insert into d(day)
WITH RECURSIVE dates AS (
    SELECT '2024-01-01'::DATE as Date,1 as Period
    UNION
    SELECT Date::DATE + INTERVAL 1 DAY as date, Period+1 FROM dates 
    WHERE Date::DATE + INTERVAL 1 DAY <= '2025-12-31'::DATE
)
SELECT date FROM dates ORDER BY Date;

-- output first and last day of each month
-- note 2024 is a leap year so last day of Feb is 2024-02-29
-- RESULT:firstOfMonth,lastOfMonth
-- RESULT:2024-01-01,2024-01-31
-- RESULT:2024-02-01,2024-02-29
-- RESULT:2024-03-01,2024-03-31
-- RESULT:2024-04-01,2024-04-30
-- RESULT:2024-05-01,2024-05-31
-- RESULT:2024-06-01,2024-06-30
-- RESULT:2024-07-01,2024-07-31
-- RESULT:2024-08-01,2024-08-31
-- RESULT:2024-09-01,2024-09-30
-- RESULT:2024-10-01,2024-10-31
-- RESULT:2024-11-01,2024-11-30
-- RESULT:2024-12-01,2024-12-31
-- RESULT:2025-01-01,2025-01-31
-- RESULT:2025-02-01,2025-02-28
-- RESULT:2025-03-01,2025-03-31
-- RESULT:2025-04-01,2025-04-30
-- RESULT:2025-05-01,2025-05-31
-- RESULT:2025-06-01,2025-06-30
-- RESULT:2025-07-01,2025-07-31
-- RESULT:2025-08-01,2025-08-31
-- RESULT:2025-09-01,2025-09-30
-- RESULT:2025-10-01,2025-10-31
-- RESULT:2025-11-01,2025-11-30
-- RESULT:2025-12-01,2025-12-31
select 
    strftime(day,'%Y-%m-%d') as firstOfMonth,
    strftime(day + INTERVAL 1 MONTH - INTERVAL 1 DAY,'%Y-%m-%d') as lastOfMonth 
from d where strftime(day,'%d') = '01';
