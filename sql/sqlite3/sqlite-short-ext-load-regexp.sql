.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_extension_functions_regex (SQL3 file segment)
-- Description: regexp extension - REGEXP operator via load_extension
-- Source: sqlite_extension_functions_regex in sqliteODBC_tests.vbs (line 2055)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_functions_regex load_extension ===

SELECT load_extension('%APPDATA%\sqlite\64bit\regexp.dll') AS loaded;

-- RESULT:r
-- RESULT:1
SELECT 'foobar' REGEXP 'foo' as r;

-- RESULT:r
-- RESULT:1
SELECT 'foobar' REGEXP 'bar' as r;

-- RESULT:r
-- RESULT:1
SELECT 'Retroactively relinquishing remunerations is reprehensible.' REGEXP ' \w{13} ' as r;

-- RESULT:r
-- RESULT:1
SELECT 'Meet me at 10:30' REGEXP '\d+:\d+' as r;

-- 1. Create a sample 'employees' table
CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    department TEXT
);

-- 2. Insert some varied data
INSERT INTO employees (full_name, email, phone, department) VALUES
('Alice Johnson', 'alice.j@company.com', '555-0102', 'Engineering'),
('Bob Smith', 'bob_smith123@gmail.com', '(555) 0199', 'Marketing'),
('Charlie Brown', 'charlie.brown@provider.net', '555.0123', 'Engineering'),
('Diana Prince', 'diana.p@company.org', '123-456-7890', 'Sales'),
('Edward Nigma', 'e.nigma@riddler.com', '555-9876', 'Security');

-- 3. Example Query: Find all employees with a 'company' email address
-- This uses the REGEXP operator usually provided by extensions
-- RESULT:full_name,email
-- RESULT:Alice Johnson,alice.j@company.com
-- RESULT:Diana Prince,diana.p@company.org
SELECT full_name, email 
FROM employees 
WHERE email REGEXP '@company\.(com|org)$';

-- 4. Example Query: Find phones matching the 555-XXXX format
-- (Handles dots, dashes, or spaces)
-- RESULT:full_name,phone
-- RESULT:Alice Johnson,555-0102
-- RESULT:Charlie Brown,555.0123
-- RESULT:Edward Nigma,555-9876
SELECT full_name, phone 
FROM employees 
WHERE phone REGEXP '555[-. ]\d{4}';

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
