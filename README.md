# csharp_DotNet8_ODBC

[![CI](https://github.com/msi-cxb/csharp_DotNet8_ODBC/actions/workflows/CI.yml/badge.svg)](https://github.com/msi-cxb/csharp_DotNet8_ODBC/actions/workflows/CI.yml)

A .NET 8 command-line tool for running SQL test files against SQLite3 and DuckDB via ODBC. It executes one or more `.sql` files, compares query results against embedded expected-result comments, and reports pass/fail counts.

---

## Usage

```
csharp_DotNet8_ODBC.exe [database folder] [database file] [data folder] [sql file pattern(s)] [options]
```

The first four arguments are required and must be specified in order:

| # | Argument | Description |
|---|---|---|
| 1 | `database folder` | Folder where the database file will be created (e.g. `.\db`) |
| 2 | `database file` | Path to the database file (e.g. `.\db\test.db`) |
| 3 | `data folder` | Folder containing data files referenced by SQL scripts |
| 4 | `sql file pattern(s)` | Glob pattern(s) selecting which `.sql` files to run (see below) |

### SQL File Pattern Syntax

| Syntax | Description |
|---|---|
| `*.sql` | All `.sql` files in the folder |
| `sqlite-ext-*.sql` | Files matching a prefix |
| `*.sql;!sqlite-ext-load-*.sql` | All `.sql` files, excluding `sqlite-ext-load-*` files |
| `*.sql;!sqlite-ext-load-*.sql;!sqlite-ext-conn-*.sql` | Multiple exclusions, each prefixed with `!` and separated by `;` |
| `sql\**\*.sql` | Recursively match `.sql` files in all subdirectories |

- Separate multiple patterns with `;`
- Prefix a pattern with `!` to exclude matching files
- Use `**` anywhere in a pattern for recursive directory matching
- Files are processed in alphabetical order

### Options

| Option | Description |
|---|---|
| `--log-level <level>` | Minimum log level: `Trace`, `Debug`, `Information` (default), `Warning`, `Error` |
| `--log-file` | Write log output to `logs/log_YYYYMMDD_HHmmss.txt` |
| `--report` | Write a markdown report to `reports/report_YYYYMMDD_HHmmss.md` |

### Examples

```
# Run all sqlite3 SQL files
csharp_DotNet8_ODBC.exe .\db .\db\test.db .\data .\sql\sqlite3\*.sql

# Run all sqlite3 files, excluding extension-load tests
csharp_DotNet8_ODBC.exe .\db .\db\test.db .\data .\sql\sqlite3\*.sql;!sqlite-ext-load-*.sql

# Recursively run all SQL files under the sql folder
csharp_DotNet8_ODBC.exe .\db .\db\test.db .\data sql\**\*.sql

# Run with file logging and a report
csharp_DotNet8_ODBC.exe .\db .\db\test.db .\data .\sql\sqlite3\*.sql --log-file --report
```

---

## SQL File Format

Each `.sql` file must declare its ODBC connection type with a `.conn` directive on the first non-comment line.

```sql
.conn sqlite3
-- or
.conn duckdb
```

### Directives

| Directive | Description |
|---|---|
| `.conn sqlite3` | Connect using the SQLite3 ODBC driver |
| `.conn sqlite3-<ext>` | Connect using SQLite3 and auto-load one extension DLL at connect time |
| `.conn sqlite3-<ext1>-<ext2>` | Connect using SQLite3 and auto-load multiple extension DLLs |
| `.conn duckdb` | Connect using the DuckDB ODBC driver (no `-<ext>` suffix; use `INSTALL`/`LOAD` SQL statements for extensions) |
| `.echo on / off` | Toggle echoing SQL statements to the log |
| `.timer on / off` | Toggle query timing |
| `.print <text>` | Print text to the log |
| `.output <file>` | Redirect RESULT output to a file |
| `.output` | Close the output file |
| `.next` | Skip the rest of the current file |
| `.quit` | Exit the program |

**SQLite3 extension loading via `.conn`**: When using `.conn sqlite3-<ext>`, the extension DLL must be present in `%APPDATA%\sqlite\64bit\<ext>.dll`. It is loaded at connection time via the ODBC `LoadExt=` parameter. Chain multiple extensions with dashes: `.conn sqlite3-fileio-regexp` loads both `fileio.dll` and `regexp.dll`. If any DLL is not found, the connection fails and the file is skipped with an error. To load an extension from a different location, use `SELECT load_extension('path\to\ext.dll')` in the SQL file instead.

### Token Substitution

The following tokens are replaced in SQL statements before execution:

| Token | Replaced with |
|---|---|
| `[[__DATAFOLDER__]]` | Fully-qualified path to the data folder argument |
| `[[__DBFOLDER__]]` | Fully-qualified path to the database folder argument |
| `%APPDATA%`, `%USERPROFILE%`, etc. | Expanded via `Environment.ExpandEnvironmentVariables()` |

### Expected Result Annotations

Place `-- RESULT:` comments immediately above a query to define the expected output. The tool compares the actual result to the expected value and counts mismatches.

```sql
-- RESULT:name,value
-- RESULT:foo,42
SELECT name, value FROM mytable;
```

`-- RESULT-ERROR:` can similarly annotate an expected ODBC error message.

> **Note:** Results containing embedded newlines cannot be compared.

### Example SQL File

```sql
.conn duckdb
.echo on

.print data folder: [[__DATAFOLDER__]]

-- RESULT:library_version,source_id,codename
-- RESULT:v1.3.2,0b83e5d2f6,Ossivalis
PRAGMA version;

SELECT * FROM '[[__DATAFOLDER__]]\mydata.csv';
```

---

## ODBC Drivers

| Database | Driver Source |
|---|---|
| SQLite3 | [msi-cxb/sqliteodbc Releases](https://github.com/msi-cxb/sqliteodbc/releases) |
| DuckDB | [DuckDB Windows ODBC installer](https://duckdb.org/install/?platform=windows&environment=odbc) |

---

## About .NET Core and ODBC

ODBC is not included in .NET Core. This project uses the `Microsoft.Windows.Compatibility` NuGet package which provides `System.Data.Odbc` on .NET 8.

Without it you will see:

```
error CS1069: The type name 'OdbcConnection' could not be found in the namespace 'System.Data.Odbc'.
```

---

## Changelog

### UPDATE 2026-04-20

- **Environment variable expansion** — SQL statements now have `Environment.ExpandEnvironmentVariables()` applied before execution. Use `%APPDATA%`, `%USERPROFILE%`, etc. directly in SQL, e.g. in `load_extension()` paths.
- **Glob-based SQL file selection** — replaced `Directory.GetFiles` with [DotNet.Glob](https://github.com/dazinator/DotNet.Glob). Argument 4 now accepts semicolon-separated glob patterns with `!` exclusion prefix and `**` recursive matching.
- **Alphabetical file processing** — resolved file list is sorted alphabetically before execution.
- **Excluded files logging** — files matched by an exclusion pattern are listed separately in the log.
- **`sqlite-ext-load-*` naming convention** — SQL files that call `load_extension()` renamed to `sqlite-ext-load-<name>.sql` to allow targeted exclusion via glob.

### UPDATE 15 August 2025

- Tweaked command line arguments
- Added DuckDB and SQLite3 `.sql` test files

### UPDATE 3 June 2025

- Initial release: run one or more `.sql` files to test ODBC drivers against SQLite3 and DuckDB
