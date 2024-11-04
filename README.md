# csharp_DotNet8_ODBC

[![CI](https://github.com/msi-cxb/csharp_DotNet8_ODBC/actions/workflows/CI.yml/badge.svg)](https://github.com/msi-cxb/csharp_DotNet8_ODBC/actions/workflows/CI.yml)

Problem: ODBC is not included in .NET Core. 

Solution: Use NuGet Package Manager to install `Microsoft.Windows.Compatibility`.

----

> [!NOTE]
>
> Requires SQLiteODBC driver. An installer is provided so that the workflow can build and run the compiled app.

This provides an example of a .NET8 project that uses `Microsoft.Windows.Compatibility` to provide ODBC compatibility.

Expected output:

```
starting... bHaveConnStr True
state Open src [.\test.db] <-- driver=SQLite3 ODBC Driver;NoWCHAR=1;database=.\test.db;
query drop table if exists company;
ExecuteNonQuery returned 0
state Open src [.\test.db] <-- driver=SQLite3 ODBC Driver;NoWCHAR=1;database=.\test.db;
query
CREATE TABLE COMPANY(
    ID INT PRIMARY KEY     NOT NULL,
    NAME           TEXT    NOT NULL,
    AGE            INT     NOT NULL,
    ADDRESS        CHAR(50),
    SALARY         REAL
);
ExecuteNonQuery returned 0
state Open src [.\test.db] <-- driver=SQLite3 ODBC Driver;NoWCHAR=1;database=.\test.db;
query
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(1, 'Paul', 32, 'California', 20000.00);

ExecuteNonQuery returned 1
state Open src [.\test.db] <-- driver=SQLite3 ODBC Driver;NoWCHAR=1;database=.\test.db;
query
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(2, 'Allen', 25, 'Texas', 15000.00);

ExecuteNonQuery returned 1
state Open src [.\test.db] <-- driver=SQLite3 ODBC Driver;NoWCHAR=1;database=.\test.db;
query
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(3, 'Teddy', 23, 'Norway', 20000.00);

ExecuteNonQuery returned 1
state Open src [.\test.db] <-- driver=SQLite3 ODBC Driver;NoWCHAR=1;database=.\test.db;
query
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(4, 'Mark', 25, 'Rich-Mond ', 65000.00);

ExecuteNonQuery returned 1
state Open src [.\test.db] <-- driver=SQLite3 ODBC Driver;NoWCHAR=1;database=.\test.db;
query
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(5, 'David', 27, 'Texas', 85000.00);

ExecuteNonQuery returned 1
state Open src [.\test.db] <-- driver=SQLite3 ODBC Driver;NoWCHAR=1;database=.\test.db;
query
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(6, 'Kim', 22, 'South-Hall', 45000.00);

ExecuteNonQuery returned 1
state Open src [.\test.db] <-- driver=SQLite3 ODBC Driver;NoWCHAR=1;database=.\test.db;
query select * from company;
Reader Start       439 milliseconds
    1 1,Paul,32,California,20000,
    2 2,Allen,25,Texas,15000,
    3 3,Teddy,23,Norway,20000,
    4 4,Mark,25,Rich-Mond ,65000,
    5 5,David,27,Texas,85000,
    6 6,Kim,22,South-Hall,45000,
Reader Finish       729 milliseconds  rowCnt 6

G:\csharp_DotNet8_ODBC\bin\Debug\net8.0\csharp_DotNet8_ODBC.exe (process 12292) exited with code 0 (0x0).
To automatically close the console when debugging stops, enable Tools->Options->Debugging->Automatically close the console when debugging stops.
Press any key to close this window . . .
```

