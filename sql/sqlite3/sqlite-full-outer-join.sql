.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_full_outer_join
-- Description: FULL OUTER JOIN - W3schools example with left, right and full joins
-- Source: sqlite_full_outer_join in sqliteODBC_tests.vbs (line 2813)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_full_outer_join ===

CREATE TABLE orders(OrderID INTEGER, CustomerID INTEGER, EmployeeID INTEGER, OrderDate VARCHAR, ShipperID INTEGER);
INSERT INTO orders VALUES(10308,2,7,'1996-09-18',3);
INSERT INTO orders VALUES(10309,37,3,'1996-09-19',1);
INSERT INTO orders VALUES(10310,77,8,'1996-09-20',2);
CREATE TABLE employees(EmployeeID INTEGER, LastName VARCHAR, FirstName VARCHAR, BirthDate VARCHAR, Photo VARCHAR);
INSERT INTO employees VALUES(1,'Davolio','Nancy','12/8/1968','EmpID1.pic');
INSERT INTO employees VALUES(2,'Fuller','Andrew','2/19/1952','EmpID2.pic');
INSERT INTO employees VALUES(3,'Leverling','Janet','8/30/1963','EmpID3.pic');

SELECT * FROM orders;
SELECT * FROM employees;

.print === left join orders to employees ===

SELECT Orders.OrderID, Employees.LastName, Employees.FirstName
FROM Orders
LEFT JOIN Employees ON Orders.EmployeeID = Employees.EmployeeID
ORDER BY Orders.OrderID;

.print === right join employees to orders ===

SELECT Orders.OrderID, Employees.LastName, Employees.FirstName
FROM Orders
RIGHT JOIN Employees ON Orders.EmployeeID = Employees.EmployeeID
ORDER BY Orders.OrderID;

.print === full outer join orders and employees ===

SELECT Orders.OrderID, Employees.LastName, Employees.FirstName
FROM Orders
FULL OUTER JOIN Employees ON Orders.EmployeeID = Employees.EmployeeID
ORDER BY Orders.OrderID;

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
