-- KNOWN LIMITATION: sqlite_extension_vfsstat cannot be loaded before the database
-- is opened when connecting via ODBC. This test cannot execute under the
-- SQLite3 ODBC Driver. No RESULT lines are present.
-- Source: sqlite_extension_vfsstat in sqliteODBC_tests.vbs (line 1461)
 .conn sqlite3

 -- .PRINT sqlite_extension_vfsstat cannot be loaded before the database is opened when connecting via ODBC.
