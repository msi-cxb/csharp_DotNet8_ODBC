-- https://duckdb.org/docs/stable/extensions/extension_distribution

.echo on
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

FORCE INSTALL postgres from '.\local_extensions';
-- INSTALL postgres;
LOAD postgres;

.print webbed not yet available for duckdb v1.4.0
-- FORCE INSTALL webbed from '.\local_extensions';
-- INSTALL webbed;
-- LOAD webbed;



-- community extension not working probably because we are not running a tagged version of duckdb
-- INSTALL h3 FROM community;
-- LOAD h3;

-- install shellfs from community;
-- load shellfs;

-- RESULT:extension_name,loaded,installed,install_path,description,aliases,extension_version,install_mode,installed_from
-- RESULT:core_functions,true,true,(BUILT-IN),Core function library,[],,STATICALLY_LINKED,
-- RESULT:ducklake,false,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\ducklake.duckdb_extension,Adds support for DuckLake, SQL as a Lakehouse Format,[],09f9b85,REPOSITORY,core
-- RESULT:excel,false,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\excel.duckdb_extension,Adds support for Excel-like format strings,[],8504be9,REPOSITORY,core
-- RESULT:fts,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\fts.duckdb_extension,Adds support for Full-Text Search Indexes,[],3937662,REPOSITORY,.\local_extensions
-- RESULT:h3,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\h3.duckdb_extension,H3 hierarchical hexagonal indexing system for geospatial data, v4.3.0,[],48eecce,REPOSITORY,.\local_extensions
-- RESULT:httpfs,false,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\httpfs.duckdb_extension,Adds support for reading and writing files over a HTTP(S) connection,[http, https, s3],354d3f4,REPOSITORY,core
-- RESULT:icu,true,true,(BUILT-IN),Adds support for time zones and collations using the ICU library,[],,STATICALLY_LINKED,
-- RESULT:json,true,true,(BUILT-IN),Adds support for JSON operations,[],,STATICALLY_LINKED,
-- RESULT:parquet,true,true,(BUILT-IN),Adds support for reading and writing parquet files,[],,STATICALLY_LINKED,
-- RESULT:postgres_scanner,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\postgres_scanner.duckdb_extension,Adds support for connecting to a Postgres database,[postgres],f012a4f,REPOSITORY,.\local_extensions
-- RESULT:spatial,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\spatial.duckdb_extension,Geospatial extension that adds support for working with spatial data and functions,[],a6a607f,REPOSITORY,.\local_extensions
-- RESULT:sqlite_scanner,true,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\sqlite_scanner.duckdb_extension,Adds support for reading and writing SQLite database files,[sqlite, sqlite3],833e105,REPOSITORY,.\local_extensions
-- RESULT:tpcds,false,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\tpcds.duckdb_extension,Adds TPC-DS data generation and query support,[],v1.4.0,REPOSITORY,core
-- RESULT:tpch,false,true,C:\Users\charlie\.duckdb\extensions\v1.4.0\windows_amd64\tpch.duckdb_extension,Adds TPC-H data generation and query support,[],v1.4.0,REPOSITORY,core
SELECT * FROM duckdb_extensions() where installed = true;
