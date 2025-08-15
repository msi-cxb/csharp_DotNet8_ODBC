-- .echo on
-- .timer on
.conn duckdb

CREATE OR REPLACE TEMPORARY TABLE timer (task_name VARCHAR, note VARCHAR, ts_msec TIMESTAMP);

.print ****************************************
.print start file
insert into timer values('file','s file to test timer',current_localtimestamp());

insert into timer values('work','s insert 10M hello',current_localtimestamp());
.print ****************************************
.print start work
CREATE TABLE work AS SELECT * FROM repeat('hello', 10000000) t1(s);
select count(1) as cnt from work;
.print end work
.print ****************************************
insert into timer values('work','e insert 10M hello',current_localtimestamp());

insert into timer values('more work','s insert 10M hello',current_localtimestamp());
.print ****************************************
.print start work
CREATE TABLE morework AS SELECT * FROM repeat('hello', 10000000) t1(s);
select count(1) as cnt from morework;
.print end work
.print ****************************************
insert into timer values('more work','e insert 10M hello',current_localtimestamp());

insert into timer values('longer work','s insert 50M hello',current_localtimestamp());
.print ****************************************
.print start work
CREATE TABLE longerwork AS SELECT * FROM repeat('hello', 50000000) t1(s);
select count(1) as cnt from morework;
.print end work
.print ****************************************
insert into timer values('longer work','e insert 50M hello',current_localtimestamp());

insert into timer values('file','e file to test timer',current_localtimestamp());
.print end file
.print ****************************************

.print
select * from
(
    SELECT 
        task_name,
        note,
        ts_msec - LAG(ts_msec, 1) OVER (PARTITION BY task_name ORDER BY ts_msec) AS ts_msec_delta
    FROM (
        SELECT *, row_number() over () as rowid FROM timer
    )
) where ts_msec_delta IS NOT NULL order by rowid;
