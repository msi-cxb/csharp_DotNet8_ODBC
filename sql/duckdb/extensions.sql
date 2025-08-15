-- https://duckdb.org/docs/stable/extensions/extension_distribution

-- .echo on
-- .timer on
.conn duckdb

PRAGMA version;

.print ****************************************************************************
.print force extension to be installed from .\local_extensions instead of internet
.print note that install copies to C:\Users\charlie\.duckdb\extensions 
.print regardless of where they come from (local or internet)
.print ****************************************************************************

FORCE INSTALL spatial from '.\local_extensions';
-- INSTALL spatial;
LOAD spatial;

FORCE INSTALL sqlite_scanner from '.\local_extensions';
-- INSTALL sqlite_scanner;
LOAD sqlite_scanner;

FORCE INSTALL fts from '.\local_extensions';
-- INSTALL fts;
LOAD fts;

FORCE INSTALL icu from '.\local_extensions';
-- INSTALL icu;
LOAD icu;

-- community extension not working probably because we are not running a tagged version of duckdb
-- INSTALL h3 FROM community;
-- LOAD h3;

-- install shellfs from community;
-- load shellfs;

-- RESULT:extension_name,loaded,installed,install_path,description,aliases,extension_version,install_mode,installed_from
-- RESULT:core_functions,true,true,(BUILT-IN),Core function library,[],,STATICALLY_LINKED,
-- RESULT:fts,true,true,C:\Users\charlie\.duckdb\extensions\fda0ba6a7a\windows_amd64\fts.duckdb_extension,Adds support for Full-Text Search Indexes,[],3aa6a18,REPOSITORY,.\local_extensions
-- RESULT:icu,true,true,(BUILT-IN),Adds support for time zones and collations using the ICU library,[],,STATICALLY_LINKED,
-- RESULT:json,true,true,(BUILT-IN),Adds support for JSON operations,[],,STATICALLY_LINKED,
-- RESULT:parquet,true,true,(BUILT-IN),Adds support for reading and writing parquet files,[],,STATICALLY_LINKED,
-- RESULT:spatial,true,true,C:\Users\charlie\.duckdb\extensions\fda0ba6a7a\windows_amd64\spatial.duckdb_extension,Geospatial extension that adds support for working with spatial data and functions,[],4be6065,REPOSITORY,.\local_extensions
-- RESULT:sqlite_scanner,true,true,C:\Users\charlie\.duckdb\extensions\fda0ba6a7a\windows_amd64\sqlite_scanner.duckdb_extension,Adds support for reading and writing SQLite database files,[sqlite, sqlite3],66a5fa2,REPOSITORY,.\local_extensions
SELECT * FROM duckdb_extensions() where installed = true;
