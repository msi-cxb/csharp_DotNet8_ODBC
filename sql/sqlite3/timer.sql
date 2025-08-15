-- .echo on
-- .timer on
.conn sqlite3

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
insert into timer values('file','the start',unixepoch('now','subsec'));

insert into timer values('task1','the start',unixepoch('now','subsec'));
drop table if exists people;
create table people (id INTEGER, income REAL, tax_rate REAL);
WITH RECURSIVE person(x) AS ( 
    SELECT 1 
    UNION ALL 
    SELECT x+1 FROM person where x < 1000000 
) 
INSERT INTO people ( id, income, tax_rate) 
SELECT 
    x, 
    70+mod(x,15)*3, 
    (15.0+(mod(x,5)*0.2)+mod(x,15))/100. 
FROM person;
-- RESULT:count(1)
-- RESULT:1000000
select count(1) from people;
insert into timer values('task 1','the end',unixepoch('now','subsec'));

insert into timer values('task2','the start',unixepoch('now','subsec'));
drop table if exists people2;
create table people2 (id INTEGER, income REAL, tax_rate REAL);
WITH RECURSIVE person(x) AS ( 
    SELECT 1 
    UNION ALL 
    SELECT x+1 FROM person where x < 100000
) 
INSERT INTO people2 ( id, income, tax_rate) 
SELECT 
    x, 
    70+mod(x,15)*3, 
    (15.0+(mod(x,5)*0.2)+mod(x,15))/100. 
FROM person;
-- RESULT:count(1)
-- RESULT:1000000
select count(1) from people2;
insert into timer values('task 2','the end',unixepoch('now','subsec'));

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

