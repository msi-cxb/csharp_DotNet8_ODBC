-- https://duckdb.org/docs/stable/extensions/extension_distribution

-- don't need to run this one normally as it is used to (re)load extensions
.quit

.echo on
-- .timer on
.conn duckdb

PRAGMA version;

-- UPDATE EXTENSIONS;

.print ****************************************************************************
.print FORCE INSTALL causes extension to be installed from .\local_extensions instead of internet
.print INSTALL copies to C:\Users\charlie\.duckdb\extensions 
.print ****************************************************************************

-- FORCE INSTALL spatial from '.\local_extensions';
INSTALL spatial;
LOAD spatial;

-- FORCE INSTALL sqlite_scanner from '.\local_extensions';
INSTALL sqlite_scanner;
LOAD sqlite_scanner;

-- FORCE INSTALL fts from '.\local_extensions';
INSTALL fts;
LOAD fts;

-- FORCE INSTALL icu from '.\local_extensions';
INSTALL icu;
LOAD icu;

-- FORCE INSTALL postgres from '.\local_extensions';
INSTALL postgres;
LOAD postgres;

-- FORCE INSTALL ducklake from '.\local_extensions';
INSTALL ducklake;
LOAD ducklake;

-- FORCE INSTALL excel from '.\local_extensions';
INSTALL excel;
LOAD excel;

-- FORCE INSTALL h3 from '.\local_extensions';
INSTALL h3 FROM community;
LOAD h3;

-- FORCE INSTALL tpch from '.\local_extensions';
INSTALL tpch;
LOAD tpch;

.print webbed not yet available for duckdb v1.4.0
-- FORCE INSTALL webbed from '.\local_extensions';
INSTALL webbed;
LOAD webbed;

-- FORCE INSTALL shellfs from '.\local_extensions';
install shellfs from community;
load shellfs;

-- RESULT:extension_name,loaded,installed,install_path,description,aliases,extension_version,install_mode,installed_from
-- RESULT:core_functions,true,true,(BUILT-IN),Core function library,[],,STATICALLY_LINKED,
-- RESULT:ducklake,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\ducklake.duckdb_extension,Adds support for DuckLake, SQL as a Lakehouse Format,[],45788f0,REPOSITORY,core
-- RESULT:excel,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\excel.duckdb_extension,Adds support for Excel-like format strings,[],8504be9,REPOSITORY,core
-- RESULT:fts,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\fts.duckdb_extension,Adds support for Full-Text Search Indexes,[],3937662,REPOSITORY,core
-- RESULT:h3,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\h3.duckdb_extension,H3 hierarchical hexagonal indexing system for geospatial data, v4.3.0,[],48eecce,REPOSITORY,community
-- RESULT:icu,true,true,(BUILT-IN),Adds support for time zones and collations using the ICU library,[],,STATICALLY_LINKED,
-- RESULT:json,true,true,(BUILT-IN),Adds support for JSON operations,[],,STATICALLY_LINKED,
-- RESULT:parquet,true,true,(BUILT-IN),Adds support for reading and writing parquet files,[],,STATICALLY_LINKED,
-- RESULT:postgres_scanner,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\postgres_scanner.duckdb_extension,Adds support for connecting to a Postgres database,[postgres],f012a4f,REPOSITORY,core
-- RESULT:shellfs,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\shellfs.duckdb_extension,,[],ee2ce42,REPOSITORY,community
-- RESULT:spatial,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\spatial.duckdb_extension,Geospatial extension that adds support for working with spatial data and functions,[],a6a607f,REPOSITORY,core
-- RESULT:sqlite_scanner,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\sqlite_scanner.duckdb_extension,Adds support for reading and writing SQLite database files,[sqlite, sqlite3],833e105,REPOSITORY,core
-- RESULT:tpch,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\tpch.duckdb_extension,Adds TPC-H data generation and query support,[],v1.4.0,REPOSITORY,core
SELECT * FROM duckdb_extensions() where installed = true;
