# csharp_DotNet8_ODBC

[![CI](https://github.com/msi-cxb/csharp_DotNet8_ODBC/actions/workflows/CI.yml/badge.svg)](https://github.com/msi-cxb/csharp_DotNet8_ODBC/actions/workflows/CI.yml)

Problem: ODBC is not included in .NET Core. 

Solution: Use NuGet Package Manager to install `Microsoft.Windows.Compatibility`.

----

## UPDATE 3 June 2025

This project has been updated so that it can run one or more `.sql` files to test ODBC driver.  

```
usage: csharp_DotNet8_ODBC.exe [duckdb OR sqlite] [database folder] [database file] [sql file glob] [data folder]

hint: use full path or relative path (e.g. '.\filename') for file names, file globbing using '*' supported for sql file path.
```

> [!NOTE]
>
> The sql files located in `.\sql\duckdb` are currently configured to be run with DuckDB. A folder `.\sql\sqlite3` is also provided for sqlite3 sql files.



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

> [!NOTE]
>
> Running the exe built by this project requires an SQLiteODBC driver. An installer is provided so that the workflow can build and run the compiled app.



