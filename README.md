# csharp_DotNet8_ODBC

[![CI](https://github.com/msi-cxb/csharp_DotNet8_ODBC/actions/workflows/CI.yml/badge.svg)](https://github.com/msi-cxb/csharp_DotNet8_ODBC/actions/workflows/CI.yml)

Problem: ODBC is not included in .NET Core. 

Solution: Use NuGet Package Manager to install `Microsoft.Windows.Compatibility`.

----

## UPDATE 15 August 2025

- Tweaked the command line arguments for the .exe
- added duckdb and sqlite .sql test files

```
csharp_DotNet8_ODBC.exe
full path to executable --> H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\csharp_DotNet8_ODBC.exe
usage: csharp_DotNet8_ODBC.exe [database folder] [database file] [data folder] [sql file glob]
hint: use full path or relative path (e.g. '.\filename') for file names, file globbing using '*' supported.
```

Example:

```sql
.echo on
-- .timer on
.conn duckdb

.print __DATAFOLDER__ [[__DATAFOLDER__]]
.print __DBFOLDER__ [[__DBFOLDER__]]

PRAGMA version;

-- https://duckdb.org/community_extensions/extensions/webbed.html
INSTALL webbed FROM community;
LOAD webbed;

-- RESULT:extension_name,loaded,installed,install_path
-- RESULT:webbed,true,true,C:\Users\charlie\.duckdb\extensions\v1.3.2\windows_amd64\webbed.duckdb_extension
SELECT extension_name,loaded,installed,install_path FROM duckdb_extensions() where installed = true and extension_name = 'webbed';

-- Read XML files directly into tables
-- RESULT:name,skills
-- RESULT:Alice,[Python, SQL]
-- RESULT:Bob,[Java, React]
SELECT * FROM '[[__DATAFOLDER__]]\webbedData\simple_nested.xml';

-- RESULT:employee_id,employee_department,employee_active,name,performance_rating,email,salary,hire_date
-- RESULT:1001,Engineering,true,Alice Johnson,4.8,alice@company.com,95000,20200315120000
-- RESULT:1002,Marketing,true,Bob Smith,4.2,bob@company.com,75000,20210601120000
-- RESULT:1003,Sales,false,Carol Davis,3.9,carol@company.com,68000,20190110120000
SELECT * FROM read_xml('[[__DATAFOLDER__]]\webbedData\employee*.xml');

-- Parse and extract from XML content using XPath
-- RESULT:result
-- RESULT:Database Guide
SELECT xml_extract_text('<book><title>Database Guide</title></book>', '//title') as result;

-- Parse and extract from HTML content
-- RESULT:result
-- RESULT:Welcome
SELECT html_extract_text('<html><body><h1>Welcome</h1></body></html>', '//h1') as result;

-- Extract HTML tables directly into DuckDB
-- RESULT:table_index,row_index,columns
-- RESULT:0,0,[Name, Age]
-- RESULT:0,1,[John, 25]
SELECT * FROM html_extract_tables('<table><tr><th>Name</th><th>Age</th></tr><tr><td>John</td><td>25</td></tr></table>');

-- Extract links and images from HTML pages
-- RESULT:html_extract_links('<a href="https://example.com">Click here</a>')
-- RESULT:[{'text': Click here, 'href': 'https://example.com', 'title': NULL, 'line_number': 1}]
SELECT html_extract_links('<a href="https://example.com">Click here</a>');

-- RESULT:html_extract_images('<img src="photo.jpg" alt="Photo" width="800">')
-- RESULT:[{'alt': Photo, 'src': photo.jpg, 'title': NULL, 'width': 800, 'height': 48, 'line_number': 1}]
SELECT html_extract_images('<img src="photo.jpg" alt="Photo" width="800">');

-- Convert between XML and JSON formats
-- RESULT:result
-- RESULT:{"person":{"age":{"#text":"30"},"name":{"#text":"John"}}}
SELECT xml_to_json('<person><name>John</name><age>30</age></person>') as result;

-- has embedded carriage return so result compare does not work
-- result should look something like
-- [result<?xml version="1.0" encoding="UTF-8"?>
-- <root><age>30</age><name>John</name></root>]
SELECT json_to_xml('{"name":"John","age":"30"}') as result;

```

Output:

```
csharp_DotNet8_ODBC.exe .\db .\db\test.db .\data .\sql\duckdb\webbed.sql
dbFolder --> H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\db
dbFile --> H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\db\test.db
dataFolder --> H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data
sqlFileSpec --> H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\sql\duckdb\webbed.sql


***************************************************
processing H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\sql\duckdb\webbed.sql...
***** Deleted H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\db\test.db
bHaveConnStr True --> *** duckdb *** H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\db\test.db
PRINT: __DATAFOLDER__ H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data
PRINT: __DBFOLDER__ H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\db
True query --> PRAGMA version;
RESULT:library_version,source_id,codename
RESULT:v1.3.2,0b83e5d2f6,Ossivalis
False query --> INSTALL webbed FROM community;
False query --> LOAD webbed;
True query --> SELECT extension_name,loaded,installed,install_path FROM duckdb_extensions() where installed = true and extension_name = 'webbed';
RESULT:extension_name,loaded,installed,install_path
RESULT:webbed,true,true,C:\Users\charlie\.duckdb\extensions\v1.3.2\windows_amd64\webbed.duckdb_extension
True query --> SELECT * FROM 'H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data\webbedData\simple_nested.xml';
RESULT:name,skills
RESULT:Alice,[Python, SQL]
RESULT:Bob,[Java, React]
True query --> SELECT * FROM read_xml('H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data\webbedData\employee*.xml');
RESULT:employee_id,employee_department,employee_active,name,performance_rating,email,salary,hire_date
RESULT:1001,Engineering,true,Alice Johnson,4.8,alice@company.com,95000,20200315120000
RESULT:1002,Marketing,true,Bob Smith,4.2,bob@company.com,75000,20210601120000
RESULT:1003,Sales,false,Carol Davis,3.9,carol@company.com,68000,20190110120000
True query --> SELECT xml_extract_text('<book><title>Database Guide</title></book>', '//title') as result;
RESULT:result
RESULT:Database Guide
True query --> SELECT html_extract_text('<html><body><h1>Welcome</h1></body></html>', '//h1') as result;
RESULT:result
RESULT:Welcome
True query --> SELECT * FROM html_extract_tables('<table><tr><th>Name</th><th>Age</th></tr><tr><td>John</td><td>25</td></tr></table>');
RESULT:table_index,row_index,columns
RESULT:0,0,[Name, Age]
RESULT:0,1,[John, 25]
True query --> SELECT html_extract_links('<a href="https://example.com">Click here</a>');
RESULT:html_extract_links('<a href="https://example.com">Click here</a>')
RESULT:[{'text': Click here, 'href': 'https://example.com', 'title': NULL, 'line_number': 1}]
True query --> SELECT html_extract_images('<img src="photo.jpg" alt="Photo" width="800">');
RESULT:html_extract_images('<img src="photo.jpg" alt="Photo" width="800">')
RESULT:[{'alt': Photo, 'src': photo.jpg, 'title': NULL, 'width': 800, 'height': 48, 'line_number': 1}]
True query --> SELECT xml_to_json('<person><name>John</name><age>30</age></person>') as result;
RESULT:result
RESULT:{"person":{"age":{"#text":"30"},"name":{"#text":"John"}}}
True query --> SELECT json_to_xml('{"name":"John","age":"30"}') as result;
RESULT:result
RESULT:<?xml version="1.0" encoding="UTF-8"?>
<root><age>30</age><name>John</name></root>

Complete. Error count: 0

```

Notes:

- files must include a line `.conn [sqlite3 or duckdb]` which defines the ODBC connection (duckdb or sqlite3) to use
- `[[__DATAFOLDER__]]` and `[[__DBFOLDER__]]` are tokens and will be replaced with the fully qualified path to the data/db folder defined on in the command line arguments. 
-  If you included the RESULT: lines above a query commented out with SQL comment `--` then the program will read this as the expected result and compare to the actual result. See the example webbed.sql script above for example. 
  - Results that have a carriage return cannot be tested
  - The count of errors (either result mismatch OR ODBC error) will be summed and reported at the end of the run.
- You can use globbing to run a folder full of .sql file. For example, `csharp_DotNet8_ODBC.exe .\db .\db\test.db .\data .\sql\duckdb\*.sql`

## UPDATE 3 June 2025

This project has been updated so that it can run one or more `.sql` files to test ODBC driver.  

```
usage: csharp_DotNet8_ODBC.exe [duckdb OR sqlite] [database folder] [database file] [sql file glob] [data folder]

hint: use full path or relative path (e.g. '.\filename') for file names, file globbing using '*' supported for sql file path.
```

> [!NOTE]
>
> The sql files located in `.\sql\duckdb` are currently configured to be run with DuckDB. A folder `.\sql\sqlite3` is also provided for sqlite3 sql files. In many cases, platform specific SQL and/or extensions are used which means you cannot run the same file in both DBs. 

## About .NET Core and ODBC 

This provides an example of a .NET8 project that uses `Microsoft.Windows.Compatibility` to provide ODBC compatibility that was removed in .NET Core (version > 4.X).

Without `Microsoft.Windows.Compatibility` you will get an error in Visual Studio 2022 like this:

```
1>G:\csharp_DotNet8_ODBC\Program.cs(107,16,107,30): error CS1069: The type name 'OdbcConnection'
could not be found in the namespace 'System.Data.Odbc'. This type has been forwarded to assembly
'System.Data.Odbc, Version=0.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51'
Consider adding a reference to that assembly.
```


Use NuGet Package Manager to install `Microsoft.Windows.Compatibility`. This will install `System.Data.Odbc.8.0.1` which solves the dependency error above. 

NuGet Install Output:

```
Installing:

Microsoft.Bcl.AsyncInterfaces.5.0.0
Microsoft.Extensions.ObjectPool.5.0.10
Microsoft.NETCore.Platforms.3.1.0
Microsoft.Win32.Registry.4.7.0
Microsoft.Win32.Registry.AccessControl.8.0.0
Microsoft.Win32.SystemEvents.8.0.0
Microsoft.Windows.Compatibility.8.0.10
runtime.linux-arm.runtime.native.System.IO.Ports.8.0.0
runtime.linux-arm64.runtime.native.System.IO.Ports.8.0.0
runtime.linux-x64.runtime.native.System.IO.Ports.8.0.0
runtime.native.System.Data.SqlClient.sni.4.7.0
runtime.native.System.IO.Ports.8.0.0
runtime.osx-arm64.runtime.native.System.IO.Ports.8.0.0
runtime.osx-x64.runtime.native.System.IO.Ports.8.0.0
runtime.win-arm64.runtime.native.System.Data.SqlClient.sni.4.4.0
runtime.win-x64.runtime.native.System.Data.SqlClient.sni.4.4.0
runtime.win-x86.runtime.native.System.Data.SqlClient.sni.4.4.0
System.CodeDom.8.0.0
System.ComponentModel.Composition.8.0.0
System.ComponentModel.Composition.Registration.8.0.0
System.Configuration.ConfigurationManager.8.0.1
System.Data.Odbc.8.0.1 <---------------------<<<<<<<<<<<<<<<
System.Data.OleDb.8.0.1
System.Data.SqlClient.4.8.6
System.Diagnostics.EventLog.8.0.1
System.Diagnostics.PerformanceCounter.8.0.1
System.DirectoryServices.8.0.0
System.DirectoryServices.AccountManagement.8.0.1
System.DirectoryServices.Protocols.8.0.0
System.Drawing.Common.8.0.10
System.IO.Packaging.8.0.1
System.IO.Ports.8.0.0
System.Management.8.0.0
System.Numerics.Vectors.4.5.0
System.Private.ServiceModel.4.10.0
System.Reflection.Context.8.0.0
System.Reflection.DispatchProxy.4.7.1
System.Runtime.Caching.8.0.1
System.Security.AccessControl.4.7.0
System.Security.Cryptography.Pkcs.8.0.1
System.Security.Cryptography.ProtectedData.8.0.0
System.Security.Cryptography.Xml.8.0.2
System.Security.Permissions.8.0.0
System.Security.Principal.Windows.5.0.0
System.ServiceModel.Duplex.4.10.0
System.ServiceModel.Http.4.10.0
System.ServiceModel.NetTcp.4.10.0
System.ServiceModel.Primitives.4.10.0
System.ServiceModel.Security.4.10.0
System.ServiceModel.Syndication.8.0.0
System.ServiceProcess.ServiceController.8.0.1
System.Speech.8.0.0
System.Text.Encoding.CodePages.8.0.0
System.Threading.AccessControl.8.0.0
System.Web.Services.Description.4.10.0
System.Windows.Extensions.8.0.0
```

## ODBC Drivers

Running the exe built by this project requires ODBC drivers for SQLite3 and DuckDB. An installer is provided so that the workflow can be run in a reproducible way with csharp_DotNet8_ODBC.

- csharp_DotNet8_ODBC\duckdbODBC64
- csharp_DotNet8_ODBC\sqliteODBC64



