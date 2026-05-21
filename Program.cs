using DatabaseLib;
using DotNet.Globbing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Serilog;
using System.Collections;
using System.Data;
using System.Data.Odbc;
using System.Diagnostics;
using System.Text;
using ILogger = Microsoft.Extensions.Logging.ILogger;


namespace csharpOdbcExample
{
    class Program
    {
        public static string appPath = System.Environment.ProcessPath;

        public static string dbType;
        public static string dbFolder;
        public static string dbFileBase;
        public static string sqlFileSpec;
        public static string dataFolder;

        public static Boolean echoInput = false;

        public static string interfaceMode;

        private const string DefaultDbFolder = "./db";
        private const string DefaultDbFileBase = ":memory:";
        private const string DefaultDataFolder = "./data";
        private const string DefaultSqlPattern = "./sql";
        private const string DefaultInterface = "native";

        private const string PostgreSqlConnType    = "postgresql";
        private const string RunSettingsFileName  = "postgresql.runsettings";
        private const string DollarQuoteDelimiter = "$$";

        private const char PatternSeparator = ';';
        private const char ExclusionPrefix = '!';

        //**********************************************************************
        static int Main(string[] args)
        {
            LogLevel? logLevelOverride = null;
            bool logFileEnabled = false;
            bool generateReport = false;
            var argList = new List<string>(args);

            for (int i = 0; i < argList.Count; i++)
            {
                string a = argList[i];
                if (a.Equals("--log-level", StringComparison.OrdinalIgnoreCase) && i + 1 < argList.Count)
                {
                    if (!Enum.TryParse<LogLevel>(argList[i + 1], ignoreCase: true, out LogLevel parsedLevel))
                    {
                        Console.WriteLine($"Unknown --log-level value '{argList[i + 1]}'. Valid values: Trace, Debug, Information, Warning, Error");
                        return 1;
                    }
                    logLevelOverride = parsedLevel;
                    argList.RemoveAt(i + 1);
                    argList.RemoveAt(i);
                    i--;
                }
                else if (a.Equals("--log-file", StringComparison.OrdinalIgnoreCase))
                {
                    logFileEnabled = true;
                    argList.RemoveAt(i);
                    i--;
                }
                else if (a.Equals("--report", StringComparison.OrdinalIgnoreCase))
                {
                    generateReport = true;
                    argList.RemoveAt(i);
                    i--;
                }
                else if ((a.Equals("--dbfolder", StringComparison.OrdinalIgnoreCase) || a.Equals("-dbfolder", StringComparison.OrdinalIgnoreCase)) && i + 1 < argList.Count)
                {
                    dbFolder = argList[i + 1];
                    argList.RemoveAt(i + 1);
                    argList.RemoveAt(i);
                    i--;
                }
                else if ((a.Equals("--dbfile", StringComparison.OrdinalIgnoreCase) || a.Equals("-dbfile", StringComparison.OrdinalIgnoreCase)) && i + 1 < argList.Count)
                {
                    dbFileBase = argList[i + 1];
                    argList.RemoveAt(i + 1);
                    argList.RemoveAt(i);
                    i--;
                }
                else if ((a.Equals("--datafolder", StringComparison.OrdinalIgnoreCase) || a.Equals("-datafolder", StringComparison.OrdinalIgnoreCase)) && i + 1 < argList.Count)
                {
                    dataFolder = argList[i + 1];
                    argList.RemoveAt(i + 1);
                    argList.RemoveAt(i);
                    i--;
                }
                else if ((a.Equals("--sql", StringComparison.OrdinalIgnoreCase) || a.Equals("-sql", StringComparison.OrdinalIgnoreCase)) && i + 1 < argList.Count)
                {
                    sqlFileSpec = argList[i + 1];
                    argList.RemoveAt(i + 1);
                    argList.RemoveAt(i);
                    i--;
                }
                else if ((a.Equals("--interface", StringComparison.OrdinalIgnoreCase) || a.Equals("-interface", StringComparison.OrdinalIgnoreCase)) && i + 1 < argList.Count)
                {
                    string val = argList[i + 1].ToLowerInvariant();
                    if (val != "odbc" && val != "native" && val != "both")
                    {
                        PrintUsage();
                        Console.Error.WriteLine($"Error: unknown --interface value '{argList[i + 1]}'. Valid values: odbc, native, both");
                        return 1;
                    }
                    interfaceMode = val;
                    argList.RemoveAt(i + 1);
                    argList.RemoveAt(i);
                    i--;
                }
                else if (a.Equals("--help", StringComparison.OrdinalIgnoreCase) || a.Equals("-help", StringComparison.OrdinalIgnoreCase))
                {
                    PrintUsage();
                    return 0;
                }
            }

            if (string.IsNullOrEmpty(dbFolder))      dbFolder      = DefaultDbFolder;
            if (string.IsNullOrEmpty(dbFileBase))    dbFileBase    = DefaultDbFileBase;
            if (string.IsNullOrEmpty(dataFolder))    dataFolder    = DefaultDataFolder;
            if (string.IsNullOrEmpty(sqlFileSpec))   sqlFileSpec   = DefaultSqlPattern;
            if (string.IsNullOrEmpty(interfaceMode)) interfaceMode = DefaultInterface;

            args = argList.ToArray();

            if (logFileEnabled)
            {
                Directory.CreateDirectory("logs");
                var logFileName = $"logs/log_{DateTime.Now:yyyyMMdd_HHmmss}.txt";
                var serilogLevel = logLevelOverride.HasValue
                    ? logLevelOverride.Value switch
                    {
                        LogLevel.Trace       => Serilog.Events.LogEventLevel.Verbose,
                        LogLevel.Debug       => Serilog.Events.LogEventLevel.Debug,
                        LogLevel.Warning     => Serilog.Events.LogEventLevel.Warning,
                        LogLevel.Error       => Serilog.Events.LogEventLevel.Error,
                        LogLevel.Critical    => Serilog.Events.LogEventLevel.Fatal,
                        _                    => Serilog.Events.LogEventLevel.Information
                    }
                    : Serilog.Events.LogEventLevel.Information;
                Serilog.Log.Logger = new Serilog.LoggerConfiguration()
                    .MinimumLevel.Is(serilogLevel)
                    .WriteTo.File(logFileName)
                    .CreateLogger();
            }

            ILoggerFactory loggerFactory;
            try
            {
                var configBuilder = new ConfigurationBuilder()
                    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false);
                if (logLevelOverride.HasValue)
                {
                    configBuilder.AddInMemoryCollection(new Dictionary<string, string?>
                    {
                        ["Logging:LogLevel:Default"] = logLevelOverride.Value.ToString()
                    });
                }
                var config = configBuilder.Build();
                loggerFactory = LoggerFactory.Create(builder =>
                {
                    builder.AddConfiguration(config.GetSection("Logging"));
                    builder.AddConsole();
                    if (logFileEnabled) builder.AddSerilog();
                });
            }
            catch (Exception)
            {
                loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
            }

            using (loggerFactory)
            {
                var logger = loggerFactory.CreateLogger<Program>();
                Int32 rtn = -1;

                logger.LogInformation("full path to executable --> {AppPath}", appPath);

                if (args.Length > 0)
                {
                    PrintUsage();
                    logger.LogError("Unrecognized arguments: {Args}", string.Join(" ", args));
                    rtn = 1;
                }
                else
                {
                    dbFolder = Path.GetFullPath(dbFolder);
                    Directory.CreateDirectory(dbFolder);
                    logger.LogInformation("dbFolder --> {DbFolder}", dbFolder);

                    logger.LogInformation("dbFileBase --> {DbFileBase}", dbFileBase);

                    dataFolder = Path.GetFullPath(dataFolder);
                    Directory.CreateDirectory(dataFolder);
                    logger.LogInformation("dataFolder --> {DataFolder}", dataFolder);

                    // auto-expand bare directory path to recursive glob
                    if (!sqlFileSpec.Contains('*') && !sqlFileSpec.Contains('?') && !sqlFileSpec.Contains('[')
                        && Directory.Exists(sqlFileSpec))
                    {
                        sqlFileSpec = Path.Combine(sqlFileSpec, "**/*.sql").Replace('\\', '/');
                    }
                    logger.LogInformation("sqlFileSpec --> {SqlFileSpec}", sqlFileSpec);

                    rtn = ProcessFiles(sqlFileSpec, loggerFactory, logger, generateReport);
                }

                return rtn;
            }
        }

        private static string DbFileExtension(string dbType) =>
            dbType.Equals("duckdb", StringComparison.OrdinalIgnoreCase) ? ".duckdb" : ".db";

        private static int CountDollarQuoteTokens(string line)
        {
            int count = 0;
            int idx = 0;
            while ((idx = line.IndexOf(DollarQuoteDelimiter, idx, StringComparison.Ordinal)) >= 0)
            {
                count++;
                idx += DollarQuoteDelimiter.Length;
            }
            return count;
        }

        private static string? FindRunSettingsFile(string sqlFilePath)
        {
            string[] searchDirs =
            [
                Path.GetDirectoryName(sqlFilePath) ?? string.Empty,
                Path.Combine(Directory.GetCurrentDirectory(), "sql", "postgresql"),
                Directory.GetCurrentDirectory()
            ];
            foreach (string dir in searchDirs)
            {
                if (string.IsNullOrEmpty(dir)) continue;
                string candidate = Path.Combine(dir, RunSettingsFileName);
                if (File.Exists(candidate)) return candidate;
            }
            return null;
        }

        private static string? ReadPostgresConnStr(string runsettingsPath, ILogger logger)
        {
            try
            {
                var doc = System.Xml.Linq.XDocument.Load(runsettingsPath);
                string? value = doc.Root
                    ?.Element("RunConfiguration")
                    ?.Element("EnvironmentVariables")
                    ?.Element("POSTGRES_CONN_STR")
                    ?.Value;
                if (string.IsNullOrEmpty(value))
                {
                    logger.LogError("POSTGRES_CONN_STR not found or empty in {Path}", runsettingsPath);
                    return null;
                }
                return value;
            }
            catch (Exception ex)
            {
                logger.LogError("Failed to parse {Path}: {Message}", runsettingsPath, ex.Message);
                return null;
            }
        }

        private static IDbRunner CreateRunner(string interfaceMode, ILoggerFactory loggerFactory)
        {
            return interfaceMode.Equals("native", StringComparison.OrdinalIgnoreCase)
                ? (IDbRunner)new NativeRunner(loggerFactory)
                : new OdbcRunner(loggerFactory.CreateLogger<OdbcRunner>());
        }

        private static void PrintUsage()
        {
            Console.WriteLine("Usage: csharp_DotNet8_ODBC.exe [options]");
            Console.WriteLine();
            Console.WriteLine("All arguments are optional. With no arguments, processes all .sql files");
            Console.WriteLine("under ./sql using in-memory databases.");
            Console.WriteLine();
            Console.WriteLine("Named Arguments:");
            Console.WriteLine($"  --dbfolder <path>    Directory where database files are created. (default: {DefaultDbFolder})");
            Console.WriteLine($"  --dbfile <base>      Base filename without extension, or :memory: for in-memory.");
            Console.WriteLine($"                       Extension appended per .conn type: .db for sqlite3, .duckdb for DuckDB.");
            Console.WriteLine($"                       (default: {DefaultDbFileBase} — no files written to disk)");
            Console.WriteLine($"  --datafolder <path>  Directory for data files referenced in SQL. (default: {DefaultDataFolder})");
            Console.WriteLine($"  --sql <pattern>      Glob pattern(s) for SQL file selection. (default: {DefaultSqlPattern})");
            Console.WriteLine("                       A bare directory is auto-expanded to <dir>/**/*.sql.");
            Console.WriteLine("                       Separate multiple patterns with ';'. Prefix with '!' to exclude.");
            Console.WriteLine($"  --interface <mode>   Driver interface: odbc, native, both (default: {DefaultInterface})");
            Console.WriteLine();
            Console.WriteLine("  Both -name and --name prefix forms are accepted.");
            Console.WriteLine();
            Console.WriteLine("Flags:");
            Console.WriteLine("  --help               Print this usage and exit (code 0).");
            Console.WriteLine("  --log-level <level>  Minimum log level: Trace, Debug, Information (default), Warning, Error.");
            Console.WriteLine("  --log-file           Write log output to logs/log_YYYYMMDD_HHmmss.txt.");
            Console.WriteLine("  --report             Write a Markdown test report to reports/report_YYYYMMDD_HHmmss.md.");
            Console.WriteLine();
            Console.WriteLine("--sql Pattern Examples:");
            Console.WriteLine("  ./sql                          → auto-expanded to ./sql/**/*.sql");
            Console.WriteLine("  ./sql/**/*.sql                 explicit recursive glob");
            Console.WriteLine("  ./sql/sqlite3/**/*.sql         only SQLite3 files");
            Console.WriteLine("  ./sql/duckdb/**/*.sql          only DuckDB files");
            Console.WriteLine("  ./sql/**/*.sql;!*encrypted*    all files except encrypted ones");
        }

        ///////////////////////////////////////////////////
        public static Int32 ProcessFiles(string sqlFileSpec, ILoggerFactory loggerFactory, ILogger logger, bool generateReport = false)
        {
            DateTime runStart = DateTime.Now;
            var fileResults = new List<(string FileName, long ErrorCount, string DbType, string Interface)>();

            var files = ResolveFileList(sqlFileSpec, logger).ToArray();

            logger.LogInformation("files to process ({Count}):", files.Length);
            foreach (string file in files)
                logger.LogInformation("  {File}", Path.GetFileName(file));

            if (files.Length > 0)
            {
                foreach (string file in files)
                {
                    logger.LogInformation("processing {File}...", file);
                    if (interfaceMode == "both")
                    {
                        var (odbcErrors,   odbcDbType)   = ProcessFile(file, "odbc",   loggerFactory, logger);
                        var (nativeErrors, nativeDbType) = ProcessFile(file, "native", loggerFactory, logger);
                        fileResults.Add((Path.GetFileName(file), odbcErrors,   odbcDbType,   "odbc"));
                        fileResults.Add((Path.GetFileName(file), nativeErrors, nativeDbType, "native"));
                    }
                    else
                    {
                        var (fileErrorCount, fileDbType) = ProcessFile(file, interfaceMode, loggerFactory, logger);
                        fileResults.Add((Path.GetFileName(file), fileErrorCount, fileDbType, interfaceMode));
                    }
                }
            }
            else
            {
                logger.LogWarning("no sql files found.");
            }

            if (generateReport)
                WriteMarkdownReport(fileResults, runStart, logger);

            return 0;
        }

        ///////////////////////////////////////////////////
        private static IEnumerable<string> ResolveFileList(string sqlFileSpec, ILogger logger)
        {
            var segments = sqlFileSpec.Split(PatternSeparator);
            var includes = segments.Where(s => !s.StartsWith(ExclusionPrefix) && s.Length > 0).ToArray();
            var excludes = segments.Where(s => s.StartsWith(ExclusionPrefix))
                                   .Select(s => s.Substring(1))
                                   .Where(s => s.Length > 0)
                                   .ToArray();

            if (includes.Length == 0)
            {
                logger.LogWarning("no sql files found.");
                return Enumerable.Empty<string>();
            }

            string firstInclude = includes[0];
            bool recursive = includes.Any(p => p.Contains("**"));

            string baseDir;
            int starStarIdx = firstInclude.IndexOf("**");
            if (starStarIdx >= 0)
            {
                string beforeStarStar = firstInclude.Substring(0, starStarIdx).TrimEnd('\\', '/');
                baseDir = string.IsNullOrEmpty(beforeStarStar)
                    ? Directory.GetCurrentDirectory()
                    : Path.GetFullPath(beforeStarStar);
            }
            else
            {
                string dirPart = Path.GetDirectoryName(firstInclude);
                baseDir = Path.GetFullPath(string.IsNullOrEmpty(dirPart) ? "." : dirPart);
            }

            if (!Directory.Exists(baseDir))
            {
                logger.LogWarning("sql file directory not found: {BaseDir}", baseDir);
                return Enumerable.Empty<string>();
            }

            var searchOption = recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
            var includeGlobs = includes.Select(p => Glob.Parse(Path.GetFileName(p))).ToArray();
            var excludeGlobs = excludes.Select(p => Glob.Parse(p)).ToArray();

            var allCandidates = Directory.EnumerateFiles(baseDir, "*", searchOption)
                .Where(filePath => includeGlobs.Any(g => g.IsMatch(Path.GetFileName(filePath))))
                .ToArray();

            var included = allCandidates
                .Where(filePath => !excludeGlobs.Any(g => g.IsMatch(Path.GetFileName(filePath))))
                .OrderBy(Path.GetFileName)
                .ToArray();

            var excluded = allCandidates
                .Where(filePath => excludeGlobs.Any(g => g.IsMatch(Path.GetFileName(filePath))))
                .OrderBy(Path.GetFileName)
                .ToArray();

            if (excluded.Length > 0)
            {
                logger.LogInformation("files excluded ({Count}):", excluded.Length);
                foreach (string file in excluded)
                    logger.LogInformation("  {File}", Path.GetFileName(file));
            }

            return included;
        }

        ///////////////////////////////////////////////////
        private static void WriteMarkdownReport(
            List<(string FileName, long ErrorCount, string DbType, string Interface)> results,
            DateTime runStart,
            ILogger logger)
        {
            string reportsDir = "reports";
            Directory.CreateDirectory(reportsDir);
            string reportPath = Path.Combine(reportsDir, $"report_{runStart:yyyyMMdd_HHmmss}.md");

            long totalErrors = results.Sum(r => r.ErrorCount);
            int rowsWithErrors = results.Count(r => r.ErrorCount > 0);

            var sb = new StringBuilder();
            sb.AppendLine("# Test Run Report");
            sb.AppendLine();
            sb.AppendLine($"**Run**: {runStart:yyyy-MM-dd HH:mm:ss}");
            sb.AppendLine();

            if (results.Count == 0)
            {
                sb.AppendLine("_No SQL files were processed._");
            }
            else
            {
                sb.AppendLine("| File | DB Type | Interface | Errors |");
                sb.AppendLine("|------|---------|-----------|--------|");
                foreach (var (fileName, errorCount, dbType, iface) in results)
                {
                    string safeFile   = fileName.Replace("|", "\\|");
                    string safeDbType = (dbType ?? string.Empty).Replace("|", "\\|");
                    if (errorCount > 0)
                        sb.AppendLine($"| **{safeFile}** | {safeDbType} | {iface} | **{errorCount}** |");
                    else
                        sb.AppendLine($"| {safeFile} | {safeDbType} | {iface} | {errorCount} |");
                }

                sb.AppendLine();
                sb.AppendLine("## Summary");
                sb.AppendLine();
                sb.AppendLine($"- Files processed: {results.Count}");
                sb.AppendLine($"- Files with errors: {rowsWithErrors}");
                sb.AppendLine($"- Total errors: {totalErrors}");
                sb.AppendLine();
                if (totalErrors == 0)
                    sb.AppendLine("**All tests passed.**");
                else
                    sb.AppendLine($"**{rowsWithErrors} file(s) failed with {totalErrors} total error(s).**");
            }

            File.WriteAllText(reportPath, sb.ToString());
            logger.LogInformation("Report written: {ReportPath}", reportPath);

            if (results.Count == 0)
            {
                logger.LogInformation("Summary: no SQL files were processed.");
            }
            else
            {
                logger.LogInformation("Summary: {FilesProcessed} file(s), {FilesWithErrors} with errors, {TotalErrors} total error(s).",
                    results.Count, rowsWithErrors, totalErrors);
                if (totalErrors == 0)
                    logger.LogInformation("All tests passed.");
                else
                    logger.LogWarning("{FilesWithErrors} file(s) failed with {TotalErrors} total error(s).", rowsWithErrors, totalErrors);
            }
        }

        ///////////////////////////////////////////////////
        public static (long ErrorCount, string DbType) ProcessFile(string file, string interfaceMode, ILoggerFactory loggerFactory, ILogger logger)
        {
            // assumes we do not have .conn yet...every file needs this
            Boolean bHaveConnStr = false;
            long errorCount = 0;

            try
            {
                IDbRunner? runner = null;
                string query = string.Empty;
                string expected = string.Empty;
                string expectedError = string.Empty;

                UInt64 ctr = 0;
                List<string> sqlLines = new List<string>();
                bool inSqlStatement = false;  // true while accumulating a multi-line SQL statement
                int beginDepth = 0;           // tracks nested BEGIN...END blocks (e.g. triggers)
                bool inDollarQuote = false;   // true inside a PostgreSQL $$...$$-delimited block

                foreach (string line in File.ReadLines(file))
                {
                    // not an empty line
                    if ( (line.Trim().Length > 0) )
                    {
                        ctr++;

                        string trimmed = line.Trim();
                        string trimmedLower = trimmed.ToLowerInvariant();

                        if (CountDollarQuoteTokens(trimmed) % 2 != 0)
                            inDollarQuote = !inDollarQuote;

                        if (inDollarQuote)
                        {
                            sqlLines.Add(line + "\n");
                            inSqlStatement = true;
                        }
                        else if(trimmed.StartsWith(".") || trimmed.StartsWith("--"))
                        {
                            // process the .conn early as the entire file will be run with this connection
                            // then we don't need to add the .conn to the sql we will process later
                            if(trimmed.StartsWith(".conn", StringComparison.OrdinalIgnoreCase))
                            {
                                dbType = line.Replace(".conn", "").Trim();

                                string resolvedDbFile;
                                if (dbType.Equals(PostgreSqlConnType, StringComparison.OrdinalIgnoreCase))
                                {
                                    string? rsPath = FindRunSettingsFile(file);
                                    if (rsPath == null)
                                    {
                                        logger.LogError("postgresql.runsettings not found. Searched: SQL file directory, ./sql/postgresql/, and working directory.");
                                        return (1, dbType);
                                    }
                                    string? pgConnStr = ReadPostgresConnStr(rsPath, logger);
                                    if (pgConnStr == null)
                                        return (1, dbType);
                                    resolvedDbFile = pgConnStr;
                                }
                                else
                                {
                                    resolvedDbFile = dbFileBase.Equals(DefaultDbFileBase, StringComparison.OrdinalIgnoreCase)
                                        ? DefaultDbFileBase
                                        : Path.Combine(dbFolder, dbFileBase + DbFileExtension(dbType));

                                    // each file we process should start with fresh empty db
                                    if (resolvedDbFile != DefaultDbFileBase && File.Exists(resolvedDbFile))
                                    {
                                        logger.LogInformation("Deleted {DbFile}", resolvedDbFile);
                                        File.Delete(resolvedDbFile);
                                    }
                                }

                                if (dbType.Equals(PostgreSqlConnType, StringComparison.OrdinalIgnoreCase) &&
                                    interfaceMode.Equals("odbc", StringComparison.OrdinalIgnoreCase))
                                {
                                    logger.LogError("PostgreSQL does not support ODBC interface mode.");
                                    return (1, dbType);
                                }

                                runner = CreateRunner(interfaceMode, loggerFactory);
                                bHaveConnStr = runner.Connect(dbType, resolvedDbFile, logger);

                                string shortDb = dbType.Equals(PostgreSqlConnType, StringComparison.OrdinalIgnoreCase)
                                    ? "PostgreSQL"
                                    : dbType.StartsWith("sqlite3", StringComparison.OrdinalIgnoreCase)
                                        ? "SQLite"
                                        : "DuckDB";
                                runner.Label = $"[{shortDb}/{interfaceMode}]";

                                logger.LogInformation("bHaveConnStr {HaveConnStr} --> *** {DbType} *** {DbFile} {Label}", bHaveConnStr, dbType, resolvedDbFile, runner.Label);
                            }
                            else if (inSqlStatement || beginDepth > 0)
                            {
                                // embedded comment inside a multi-line SQL statement — strip it from the query
                            }
                            else
                            {
                                // sqlite3 dot commands and single line comments between statements
                                sqlLines.Add(line + "<<<<SQLSPLIT>>>>");
                            }
                        }
                        else if (beginDepth > 0)
                        {
                            // inside a BEGIN...END block (e.g. trigger body)
                            if (trimmedLower == "begin") beginDepth++;

                            if (trimmedLower == "end;")
                            {
                                beginDepth--;
                                if (beginDepth == 0)
                                {
                                    sqlLines.Add(line + "<<<<SQLSPLIT>>>>");
                                    inSqlStatement = false;
                                }
                                else
                                {
                                    sqlLines.Add(line + " ");
                                }
                            }
                            else
                            {
                                sqlLines.Add(line + " ");
                            }
                        }
                        else if ((inSqlStatement && trimmedLower == "begin") || trimmedLower.EndsWith(" begin"))
                        {
                            // BEGIN keyword following accumulated SQL lines (trigger body opener)
                            beginDepth++;
                            sqlLines.Add(line + " ");
                        }
                        else if( !line.TrimEnd().EndsWith(";") )
                        {
                            // for multi line sql statements
                            sqlLines.Add(line + " ");
                            inSqlStatement = true;
                        }
                        else
                        {
                            // single line sql statements
                            sqlLines.Add(line + "<<<<SQLSPLIT>>>>");
                            inSqlStatement = false;
                        }
                    }
                }

                // create array of single line sql statements from the input sql file, comments and dot commands
                string[] sql = String.Join("", sqlLines.ToArray()).Split("<<<<SQLSPLIT>>>>");

                if (bHaveConnStr && runner != null)
                {
                    using (runner)
                    {
                        foreach (string line in sql)
                        {
                            if (line.TrimStart().StartsWith(".quit", StringComparison.OrdinalIgnoreCase))
                            {
                                System.Environment.Exit(1);
                            }
                            else if (line.TrimStart().StartsWith(".next", StringComparison.OrdinalIgnoreCase))
                            {
                                logger.LogInformation(".next directive: skipping remainder of file.");
                                break;
                            }
                            else if (line.TrimStart().StartsWith(".output", StringComparison.OrdinalIgnoreCase))
                            {
                                // .output with nothing else writes output to file and then turns off output to file
                                if( line.Trim().Replace(".output", "").Length == 0 )
                                {
                                    if (runner!.Sb.Length > 0)
                                    {
                                        logger.LogTrace($"outputFile {runner.OutputFile}");
                                        logger.LogTrace($"sb {runner.Sb.ToString()}");
                                        File.WriteAllText(runner.OutputFile, runner.Sb.ToString());
                                    }
                                    runner.Output = false;
                                    runner.OutputFile = string.Empty;
                                    runner.Sb.Clear();
                                }
                                else
                                {
                                    // .output [filename]
                                    runner!.Output = true;
                                    runner.Sb.Clear();
                                    string outputArg = line.Trim().Substring(".output".Length).Trim();
                                    outputArg = outputArg.Replace("[[__DATAFOLDER__]]", dataFolder);
                                    outputArg = outputArg.Replace("[[__DBFOLDER__]]", dbFolder);
                                    var b = Path.IsPathFullyQualified(outputArg);
                                    runner.OutputFile = Path.GetFullPath(outputArg);
                                    if (File.Exists(runner.OutputFile))
                                    {
                                        File.Delete(runner.OutputFile);
                                    }
                                }
                                logger.LogDebug($"file output {runner.Output} file [{runner.OutputFile}]");
                            }
                            else if (line.TrimStart().StartsWith(".echo on", StringComparison.OrdinalIgnoreCase))
                            {
                                runner!.Echo = true;
                            }
                            else if (line.TrimStart().StartsWith(".echo off", StringComparison.OrdinalIgnoreCase))
                            {
                                runner!.Echo = false;
                            }
                            else if (line.TrimStart().StartsWith(".timer on", StringComparison.OrdinalIgnoreCase))
                            {
                                runner!.Timer = true;
                            }
                            else if (line.TrimStart().StartsWith(".timer off", StringComparison.OrdinalIgnoreCase))
                            {
                                runner!.Timer = false;
                            }
                            else if (line.TrimStart().StartsWith("-- RESULT:", StringComparison.OrdinalIgnoreCase))
                            {
                                var resultStr = line.TrimStart().Replace("-- RESULT:", "");
                                resultStr = resultStr.Replace("[[__DATAFOLDER__]]", dataFolder);
                                resultStr = resultStr.Replace("[[__DBFOLDER__]]", dbFolder);
                                expected += resultStr;
                            }
                            else if (line.TrimStart().StartsWith("-- RESULT-ERROR:", StringComparison.OrdinalIgnoreCase))
                            {
                                expectedError += line.TrimStart().Replace("-- RESULT-ERROR:", "").Trim();
                            }
                            else if (line.TrimStart().StartsWith(".print", StringComparison.OrdinalIgnoreCase))
                            {
                                var p = line.Replace(".print", "").Trim();
                                p = p.Replace("[[__DATAFOLDER__]]", dataFolder);
                                p = p.Replace("[[__DBFOLDER__]]", dbFolder);
                                logger.LogInformation("PRINT: {PrintContent}", p);
                            }
                            else if (line.TrimStart().StartsWith(".system", StringComparison.OrdinalIgnoreCase))
                            {
                                var c = line.Replace(".system", "").Trim();
                                c = c.Replace("[[__DATAFOLDER__]]", dataFolder);
                                c = c.Replace("[[__DBFOLDER__]]", dbFolder);
                                logger.LogDebug("SYSTEM: {Command}", c);
                                System.Diagnostics.Process process = new System.Diagnostics.Process();
                                System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo();
                                startInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                                startInfo.FileName = "cmd.exe";
                                startInfo.Arguments = "/C " + c;
                                process.StartInfo = startInfo;
                                process.Start();
                            }
                            else if (line.TrimStart().StartsWith(".delete", StringComparison.OrdinalIgnoreCase))
                            {
                                var delPath = line.TrimStart().Substring(".delete".Length).Trim();
                                delPath = delPath.Replace("[[__DATAFOLDER__]]", dataFolder);
                                delPath = delPath.Replace("[[__DBFOLDER__]]", dbFolder);
                                if (delPath.Contains('*') || delPath.Contains('?'))
                                {
                                    var dir = Path.GetDirectoryName(delPath) ?? ".";
                                    var pattern = Path.GetFileName(delPath);
                                    foreach (var f in Directory.GetFiles(dir, pattern))
                                    {
                                        File.Delete(f);
                                        logger.LogInformation("DELETE file: {FilePath}", f);
                                    }
                                }
                                else if (File.Exists(delPath))
                                {
                                    File.Delete(delPath);
                                    logger.LogInformation("DELETE file: {FilePath}", delPath);
                                }
                                else if (Directory.Exists(delPath))
                                {
                                    Directory.Delete(delPath, recursive: true);
                                    logger.LogInformation("DELETE folder: {FilePath}", delPath);
                                }
                                else
                                {
                                    logger.LogWarning("DELETE: path not found, skipping: {FilePath}", delPath);
                                }
                            }
                            else if (!line.TrimStart().StartsWith(".") && !line.TrimStart().StartsWith("--") && line.TrimStart().Length > 0)
                            {
                                // if we got here then we have a sql statement
                                string sqlstr = line.Trim();

                                sqlstr = sqlstr.Replace("[[__DATAFOLDER__]]", dataFolder);
                                sqlstr = sqlstr.Replace("[[__DBFOLDER__]]", dbFolder);
                                sqlstr = Environment.ExpandEnvironmentVariables(sqlstr);

                                // find the sql statements that require ExecuteQuery

                                bool executeQuery = new string[] {
                                    "analyze",
                                    "create property graph",
                                    "describe",
                                    "execute",
                                    "explain",
                                    "from",
                                    "pragma",
                                    "select",
                                    "show",
                                    "summarize",
                                    "with"
                                }.Any(s => sqlstr.IndexOf(s, StringComparison.OrdinalIgnoreCase) >= 0);

                                bool executeNonQuery = new string[] {
                                    "alter",
                                    "attach",
                                    "begin",
                                    "commit",
                                    "copy",
                                    "create",
                                    "delete",
                                    "drop",
                                    "insert",
                                    "install",
                                    "load",
                                    "rollback",
                                    "set",
                                    "update",
                                    "use",
                                    "vacuum"
                                }.Any(s => sqlstr.StartsWith(s, StringComparison.OrdinalIgnoreCase) == true);

                                runner!.Execute(sqlstr, executeQuery, expected, expectedError, logger);
                                //o.Execute(sqlstr, !executeNonQuery, expected);

                                expected = string.Empty;
                                expectedError = string.Empty;
                            }                        
                        }
                        errorCount = runner.ErrorCount;
                        logger.LogInformation("{Label} Complete. Error count: {ErrorCount}", runner.Label, runner.ErrorCount);
                    }
                }
                else
                {
                    runner?.Dispose();
                    if (string.IsNullOrEmpty(dbType))
                    {
                        logger.LogError(".conn directive not found in file. Add '.conn [sqlite3|sqlite3-<ext>|duckdb]' at the top.");
                        errorCount = 1;
                    }
                    else
                    {
                        logger.LogError("Unrecognised connection type '{DbType}'. Expected: sqlite3, sqlite3-<ext>, duckdb, or postgresql.", dbType);
                        errorCount = 1;
                    }
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "ProcessFile() Exception: {Message}", ex.Message);
                return (-1, dbType);
            }
            finally
            {
            }
            return (errorCount, dbType);
        }
    }


    //**********************************************************************
    interface IDbRunner : IDisposable
    {
        bool Connect(string dbType, string dbPath, ILogger logger);
        (long AffectedRecords, string DataTableString) Execute(string query, bool executeQuery, string expected, string expectedError, ILogger logger);
        long ErrorCount { get; }
        bool Echo { get; set; }
        bool Timer { get; set; }
        bool Output { get; set; }
        string OutputFile { get; set; }
        string Label { get; set; }
        StringBuilder Sb { get; }
    }

    //**********************************************************************
    class OdbcRunner : IDbRunner
    {
        private readonly MyOdbcClass _inner;
        public string Label { get; set; } = string.Empty;

        public OdbcRunner(ILogger logger) { _inner = new MyOdbcClass(logger); }

        public long ErrorCount => _inner.errorCount;
        public bool Echo { get => _inner.echo; set => _inner.echo = value; }
        public bool Timer { get => _inner.timer; set => _inner.timer = value; }
        public bool Output { get => _inner.output; set => _inner.output = value; }
        public string OutputFile { get => _inner.outputFile; set => _inner.outputFile = value; }
        public StringBuilder Sb => _inner.sb;

        public bool Connect(string dbType, string dbPath, ILogger logger)
        {
            if (!_inner.GetConnectionString(dbType, dbPath)) return false;
            try
            {
                _inner.connection = new OdbcConnection(_inner.connStr);
                _inner.connection.Open();
                return true;
            }
            catch (Exception ex)
            {
                logger.LogError("OdbcRunner.Connect failed: {Message}", ex.Message);
                return false;
            }
        }

        public (long AffectedRecords, string DataTableString) Execute(
            string query, bool executeQuery, string expected, string expectedError, ILogger logger)
            => _inner.Execute(query, executeQuery, expected, expectedError);

        public void Dispose() => _inner.connection?.Dispose();
    }

    //**********************************************************************
    class NativeRunner : IDbRunner
    {
        private readonly ILoggerFactory _loggerFactory;
        private IDatabaseService? _service;
        private long _errorCount;
        public string Label { get; set; } = string.Empty;

        public NativeRunner(ILoggerFactory loggerFactory) { _loggerFactory = loggerFactory; }

        public long ErrorCount => _errorCount;
        public bool Echo { get; set; }
        public bool Timer { get; set; }
        public bool Output { get; set; }
        public string OutputFile { get; set; } = string.Empty;
        public StringBuilder Sb { get; } = new StringBuilder();

        public bool Connect(string dbType, string dbPath, ILogger logger)
        {
            try
            {
                IDatabaseFactory factory;
                string connStr;

                if (dbType.Equals("duckdb", StringComparison.OrdinalIgnoreCase))
                {
                    factory = new DuckDbFactory(_loggerFactory);
                    connStr = dbPath.Equals(":memory:", StringComparison.OrdinalIgnoreCase)
                        ? "Data Source=:memory:"
                        : $"Data Source={dbPath}";
                }
                else if (dbType.Equals("sqlite3", StringComparison.OrdinalIgnoreCase)
                         || dbType.StartsWith("sqlite3-", StringComparison.OrdinalIgnoreCase))
                {
                    factory = new SqliteFactory(_loggerFactory);
                    connStr = dbPath.Equals(":memory:", StringComparison.OrdinalIgnoreCase)
                        ? "Data Source=:memory:;Version=3;"
                        : $"Data Source={dbPath};Version=3;";
                }
                else if (dbType.Equals("postgresql", StringComparison.OrdinalIgnoreCase))
                {
                    factory = new PostgreSqlFactory(_loggerFactory);
                    connStr = dbPath;
                }
                else
                {
                    logger.LogError("NativeRunner.Connect: unknown dbType '{DbType}'", dbType);
                    return false;
                }

                _service = factory.CreateDatabaseService();
                _service.ConnectAsync(connStr).GetAwaiter().GetResult();
                logger.LogInformation("connStr {ConnStr}", connStr);

                if (_service is SqliteService sqliteSvcForLoad)
                    sqliteSvcForLoad.EnableSqlExtensionLoadingAsync(true).GetAwaiter().GetResult();


                if (dbType.StartsWith("sqlite3-", StringComparison.OrdinalIgnoreCase)
                    && _service is SqliteService sqliteSvc)
                {
                    string extFolder = Environment.ExpandEnvironmentVariables(@"%APPDATA%\sqlite\64bit");
                    foreach (string token in ParseExtensionTokens(dbType.Substring("sqlite3-".Length)))
                    {
                        string dllPath = Path.Combine(extFolder, token + ".dll");
                        if (!File.Exists(dllPath))
                        {
                            logger.LogError("Extension DLL not found: {DllPath}", dllPath);
                            return false;
                        }
                        sqliteSvc.LoadExtensionAsync(dllPath).GetAwaiter().GetResult();
                    }
                }

                return true;
            }
            catch (Exception ex)
            {
                logger.LogError("NativeRunner.Connect failed: {Message}", ex.Message);
                return false;
            }
        }

        public (long AffectedRecords, string DataTableString) Execute(
            string query, bool executeQuery, string expected, string expectedError, ILogger logger)
        {
            if (_service == null)
            {
                logger.LogError("NativeRunner.Execute: not connected");
                _errorCount++;
                return (0, string.Empty);
            }

            var stopwatch = new Stopwatch();
            string result = string.Empty;
            long rowsAffected = 0;

            try
            {
                if (Echo)
                    logger.LogInformation("{ExecuteQuery} query --> {Query}", executeQuery, query);

                if (executeQuery)
                {
                    bool exceptionThrown = false;
                    try
                    {
                        stopwatch.Start();
                        DataTable dt = _service.ExecuteQueryAsync(query).GetAwaiter().GetResult();
                        if (Timer) logger.LogInformation("TIMER: {Elapsed}", MyOdbcClass.ToPrettyFormat(stopwatch.Elapsed));
                        stopwatch.Stop();

                        if (dt.Rows.Count > 0)
                        {
                            var hdr = new StringBuilder();
                            for (int i = 0; i < dt.Columns.Count; i++)
                            {
                                if (i > 0) hdr.Append(',');
                                hdr.Append(dt.Columns[i].ColumnName);
                            }
                            string headerStr = hdr.ToString();
                            logger.LogInformation("RESULT:{Result}", headerStr);
                            result += headerStr;
                            if (Output) Sb.AppendLine(headerStr);

                            foreach (DataRow row in dt.Rows)
                            {
                                var rowSb = new StringBuilder();
                                for (int i = 0; i < dt.Columns.Count; i++)
                                {
                                    if (i > 0) rowSb.Append(',');
                                    object cell = row[i];
                                    rowSb.Append(cell == DBNull.Value ? "null" : FormatCell(cell));
                                }
                                string rowStr = rowSb.ToString();
                                logger.LogInformation("RESULT:{Result}", rowStr);
                                result += rowStr;
                                if (Output) Sb.AppendLine(rowStr);
                            }
                        }

                        if (expected.Length > 0)
                        {
                            string normalResult = result.Trim().Replace("\r\n", "\n").Replace("\r", "\n");
                            string normalExpect = expected.Trim().Replace("\r\n", "\n").Replace("\r", "\n");
                            if (normalResult != normalExpect)
                            {
                                int diffIdx = MyOdbcClass.FirstDiff(normalResult, normalExpect);
                                string diffCtx = diffIdx >= 0
                                    ? BuildDiffContext(normalResult, normalExpect, diffIdx)
                                    : $" | lengths differ: result={normalResult.Length} expect={normalExpect.Length}";
                                logger.LogWarning($"\n\nRESULTS MISMATCH!{diffCtx}\nresult [{normalResult}]\nexpect [{normalExpect}]");
                                _errorCount++;
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        exceptionThrown = true;
                        string actualError = ex.Message;
                        if (expectedError.Length > 0)
                        {
                            if (actualError.IndexOf(expectedError, StringComparison.OrdinalIgnoreCase) >= 0)
                                logger.LogInformation("RESULT-ERROR PASS: {Expected}", expectedError);
                            else
                            {
                                logger.LogWarning("RESULT-ERROR MISMATCH\n  expected [{Expected}]\n  actual   [{Actual}]", expectedError, actualError);
                                _errorCount++;
                            }
                        }
                        else
                        {
                            logger.LogError("ExecuteQuery Exception: {Message}", ex.Message);
                            _errorCount++;
                        }
                    }

                    if (expectedError.Length > 0 && !exceptionThrown)
                    {
                        logger.LogWarning("RESULT-ERROR: expected exception did not occur [{Expected}]", expectedError);
                        _errorCount++;
                    }

                    Console.Out.Flush();
                    Console.Error.Flush();
                }
                else
                {
                    bool exceptionThrown = false;
                    try
                    {
                        stopwatch.Start();
                        rowsAffected = _service.ExecuteNonQueryAsync(query).GetAwaiter().GetResult();
                        if (Timer) logger.LogInformation("TIMER: {Elapsed} returned {RowCount}", MyOdbcClass.ToPrettyFormat(stopwatch.Elapsed), rowsAffected);
                        stopwatch.Stop();
                    }
                    catch (Exception ex)
                    {
                        exceptionThrown = true;
                        string actualError = ex.Message;
                        if (expectedError.Length > 0)
                        {
                            if (actualError.IndexOf(expectedError, StringComparison.OrdinalIgnoreCase) >= 0)
                                logger.LogInformation("RESULT-ERROR PASS: {Expected}", expectedError);
                            else
                            {
                                logger.LogWarning("RESULT-ERROR MISMATCH\n  expected [{Expected}]\n  actual   [{Actual}]", expectedError, actualError);
                                _errorCount++;
                            }
                        }
                        else
                        {
                            logger.LogError("ExecuteNonQuery Exception: {Message}", ex.Message);
                            _errorCount++;
                        }
                    }

                    if (expectedError.Length > 0 && !exceptionThrown)
                    {
                        logger.LogWarning("RESULT-ERROR: expected exception did not occur [{Expected}]", expectedError);
                        _errorCount++;
                    }

                    Console.Out.Flush();
                    Console.Error.Flush();
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "NativeRunner.Execute Exception: {Message}", ex.Message);
                _errorCount++;
            }

            return (rowsAffected, result);
        }

        public void Dispose()
        {
            if (_service != null)
                _service.DisposeAsync().AsTask().GetAwaiter().GetResult();
        }

        private static string FormatCell(object cellObj)
        {
            var inv = System.Globalization.CultureInfo.InvariantCulture;
            return cellObj switch
            {
                string s when s == "True"  => "true",
                string s when s == "False" => "false",
                string s    => s,
                double d    => d.ToString(inv),
                float f     => f.ToString(inv),
                byte b      => b.ToString(inv),
                byte[] ba   => Encoding.Default.GetString(ba),
                System.IO.Stream st => new System.IO.StreamReader(st, Encoding.Default).ReadToEnd(),
                short s16   => s16.ToString(inv),
                int i32     => i32.ToString(inv),
                long i64    => i64.ToString(inv),
                decimal dec => dec.ToString(inv),
                TimeSpan ts => ts.ToString("c"),
                TimeOnly t  => t.ToString("HH:mm:ss"),
                DateOnly d  => new DateTime(d.Year, d.Month, d.Day).ToString("yyyyMMddhhmmss"),
                DateTime dt => dt.ToString("yyyyMMddhhmmss"),
                bool boolVal => boolVal ? "true" : "false",
                IDictionary dict => "{" + string.Join(", ", dict.Keys.Cast<object>().Select(k => $"'{k}': {(dict[k] is null ? "NULL" : FormatCell(dict[k]!))}")) + "}",
                IEnumerable col => "[" + string.Join(", ", col.Cast<object>().Select(o => o is null ? "NULL" : FormatCell(o))) + "]",
                _           => cellObj.ToString() ?? string.Empty
            };
        }

        private static string BuildDiffContext(string normalResult, string normalExpect, int diffIdx)
        {
            char rCh = diffIdx < normalResult.Length ? normalResult[diffIdx] : '\0';
            char eCh = diffIdx < normalExpect.Length ? normalExpect[diffIdx] : '\0';
            string rSnip = MyOdbcClass.StringContext(normalResult, diffIdx, 10);
            string eSnip = MyOdbcClass.StringContext(normalExpect, diffIdx, 10);
            return $" | first diff at char {diffIdx}: result=0x{(int)rCh:X} expect=0x{(int)eCh:X}\n  result ctx: [{rSnip}]\n  expect ctx: [{eSnip}]";
        }

        private static string[] ParseExtensionTokens(string suffix)
        {
            var tokenList = new List<string>();
            var current = new StringBuilder();
            bool inQuotes = false;
            foreach (char c in suffix)
            {
                if (c == '"')              { inQuotes = !inQuotes; }
                else if (c == '-' && !inQuotes) { if (current.Length > 0) { tokenList.Add(current.ToString()); current.Clear(); } }
                else                       { current.Append(c); }
            }
            if (current.Length > 0) tokenList.Add(current.ToString());
            return tokenList.ToArray();
        }
    }

    //**********************************************************************
    public class MyOdbcClass
    {
        private readonly ILogger _logger;

        public MyOdbcClass(ILogger logger) { _logger = logger; }

        public string _dbType = "";
        public string connStr = "";
        public OdbcConnection connection = null;
        public Boolean echo = false;
        public Boolean timer = false;
        public Boolean output = false;
        public string outputFile = string.Empty;
        public StringBuilder sb = new StringBuilder();
        public static string driverVersion;

        public Int64 errorCount = 0;

        public Boolean GetConnectionString(string dbType, string dbPath)
        {
            Boolean rtnVal = true;
            _dbType = dbType;
            string versionQuery = string.Empty;

            if (dbType == "sqlite3" || dbType.StartsWith("sqlite3-", StringComparison.OrdinalIgnoreCase))
            {
                string baseConn = @"driver=SQLite3 ODBC Driver;NoWCHAR=1;database=" + dbPath + @";";
                versionQuery = "SELECT sqlite_version() AS version;";

                if (dbType.StartsWith("sqlite3-", StringComparison.OrdinalIgnoreCase))
                {
                    string suffix = dbType.Substring("sqlite3-".Length);
                    var tokenList = new List<string>();
                    var current = new StringBuilder();
                    bool inQuotes = false;
                    foreach (char c in suffix)
                    {
                        if (c == '"')
                        {
                            inQuotes = !inQuotes;
                        }
                        else if (c == '-' && !inQuotes)
                        {
                            if (current.Length > 0) { tokenList.Add(current.ToString()); current.Clear(); }
                        }
                        else
                        {
                            current.Append(c);
                        }
                    }
                    if (current.Length > 0) tokenList.Add(current.ToString());
                    string[] tokens = tokenList.ToArray();
                    string extFolder = Environment.ExpandEnvironmentVariables(@"%APPDATA%\sqlite\64bit");
                    var dllPaths = new List<string>();
                    bool allFound = true;

                    foreach (string token in tokens)
                    {
                        string dllPath = Path.Combine(extFolder, token + ".dll");
                        if (!File.Exists(dllPath))
                        {
                            _logger.LogError("Extension DLL not found: {DllPath}", dllPath);
                            allFound = false;
                        }
                        else
                        {
                            dllPaths.Add(dllPath);
                        }
                    }

                    if (!allFound)
                    {
                        rtnVal = false;
                        return rtnVal;
                    }

                    connStr = baseConn + "LoadExt=" + string.Join(",", dllPaths) + ";";
                }
                else
                {
                    connStr = baseConn;
                }
            }
            else if (dbType == "duckdb")
            {
                connStr = @"Driver=DuckDB Driver;Database=" + dbPath + ";allow_unsigned_extensions=true;";
                versionQuery = "SELECT version() as version;";
            }
            else
            {
                _logger.LogError("unknown dbType: {DbType}", dbType);
                rtnVal = false;
                return rtnVal;
            }

            if(dbPath != ":memory:")
            {
                FileInfo fi = new FileInfo(dbPath);
                string extension = fi.Extension.ToLower();

                if (fi.Exists == false)
                {
                    _logger.LogInformation("file does not exist, creating {DbPath}", dbPath);
                }
            }

            _logger.LogInformation($"connStr {connStr}");

            using (OdbcConnection connection = new OdbcConnection(connStr))
            {
                try
                {
                    connection.Open();
                    string query = versionQuery;

                    using (OdbcCommand command = new OdbcCommand(query, connection))
                    {
                        using (OdbcDataReader reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                driverVersion = $"v{reader["version"].ToString()}";
                            }
                        }
                    }
                }
                catch (OdbcException ex)
                {
                    _logger.LogError("driverVersion ODBC Error: {Message}", ex.Message);
                }
                catch (Exception ex)
                {
                    _logger.LogError("driverVersion Error: {Message}", ex.Message);
                }
            }

            return rtnVal;
        }

        public (Int64 AffectedRecords, String DataTableString) Execute(string query, Boolean executeQuery, string expected, string expectedError = "")
        {
            Int64 rtnCount = -999;
            Stopwatch stopwatch = new Stopwatch();
            TimeSpan timeSpan;
            DataSet dataSet = new DataSet();
            DataTable dataTable = null;
            string result = string.Empty;

            try
            {
                OdbcCommand command = new OdbcCommand(query, connection);

                if (echo)
                {
                    _logger.LogInformation("{ExecuteQuery} query --> {Query}", executeQuery, query);
                }

                if (executeQuery == true)
                {
                    Int64 rowCnt = 0;
                    Int64 columnCnt = 0;
                    bool exceptionThrown = false;

                    try
                    {
                        stopwatch.Start();
                        OdbcDataReader reader = command.ExecuteReader();
                        _logger.LogDebug($"    ExecuteReader:{reader.HasRows} {reader.FieldCount}");
                        if (timer) { _logger.LogInformation("TIMER: {Elapsed}", ToPrettyFormat(stopwatch.Elapsed)); }

                        string s = string.Empty;
                        if (reader.HasRows)
                        {
                            for (int i = 0; i < reader.FieldCount; i++)
                            {
                                s += reader.GetName(i);
                                if (i < (reader.FieldCount - 1))
                                {
                                    s += ",";
                                }
                            }
                            _logger.LogInformation("RESULT:{Result}", s);
                            result += s;
                            if (output) { sb.AppendLine(s); }

                            while (reader.Read())
                            {
                                rowCnt += 1;
                                s = string.Empty;
                                for (int i = 0; i < reader.FieldCount; i++)
                                {
                                    if (reader.IsDBNull(i))
                                    {
                                        s += "null";
                                    }
                                    else
                                    {
                                        object cellObj;
                                        try
                                        {
                                            cellObj = reader[i];
                                        }
                                        catch (Exception ex)
                                        {
                                            _logger.LogWarning("column {Index} typed fetch failed ({Message}), retrying as string", i, ex.Message);
                                            cellObj = reader.GetString(i);
                                        }

                                        _logger.LogDebug("reader[{Index}].GetType() {Type}", i, cellObj.GetType());

                                        switch (cellObj.GetType().ToString())
                                        {
                                            case "System.String":
                                                s += (string)cellObj;
                                                break;
                                            case "System.Double":
                                                s += ((System.Double)cellObj).ToString();
                                                break;
                                            case "System.Byte":
                                                s += ((System.Byte)cellObj).ToString();
                                                break;
                                            case "System.Byte[]":
                                                s += Encoding.Default.GetString((System.Byte[])cellObj);
                                                break;
                                            case "System.Int16":
                                                s += ((System.Int16)cellObj).ToString();
                                                break;
                                            case "System.Int32":
                                                s += ((System.Int32)cellObj).ToString();
                                                break;
                                            case "System.Int64":
                                                s += ((System.Int64)cellObj).ToString();
                                                break;
                                            case "System.Decimal":
                                                s += ((System.Decimal)cellObj).ToString();
                                                break;
                                            case "System.TimeSpan":
                                                s += ((System.TimeSpan)cellObj).ToString("c");
                                                break;
                                            case "System.DateTime":
                                                s += ((System.DateTime)cellObj).ToString("yyyyMMddhhmmss");
                                                break;
                                            default:
                                                _logger.LogWarning("unhandled type: {Type}", cellObj.GetType());
                                                break;
                                        }
                                    }
                                    if (i < (reader.FieldCount-1))
                                    {
                                        s += ",";
                                    }
                                }
                                _logger.LogInformation("RESULT:{Result}", s);
                                result += s;
                                sb.AppendLine(s);
                            }
                        }

                        if (expected.Length > 0)
                        {
                            string normalResult = result.Trim().Replace("\r\n", "\n").Replace("\r", "\n");
                            string normalExpect = expected.Trim().Replace("\r\n", "\n").Replace("\r", "\n");
                            if (normalResult != normalExpect)
                            {
                                int diffIdx = FirstDiff(normalResult, normalExpect);
                                string diffCtx;
                                if (diffIdx >= 0)
                                {
                                    char rCh = diffIdx < normalResult.Length ? normalResult[diffIdx] : '\0';
                                    char eCh = diffIdx < normalExpect.Length ? normalExpect[diffIdx] : '\0';
                                    string rSnip = StringContext(normalResult, diffIdx, 10);
                                    string eSnip = StringContext(normalExpect, diffIdx, 10);
                                    diffCtx = $" | first diff at char {diffIdx}: result=0x{(int)rCh:X} expect=0x{(int)eCh:X}\n  result ctx: [{rSnip}]\n  expect ctx: [{eSnip}]";
                                }
                                else
                                {
                                    diffCtx = $" | lengths differ: result={normalResult.Length} expect={normalExpect.Length}";
                                }
                                _logger.LogWarning($"\n\nRESULTS MISMATCH!{diffCtx}\nresult [{normalResult}]\nexpect [{normalExpect}]");
                                errorCount += 1;
                            }
                        }

                        reader.Close();
                        stopwatch.Stop();
                    }
                    catch (OdbcException ex)
                    {
                        exceptionThrown = true;
                        StringBuilder errors = new StringBuilder();
                        foreach (OdbcError err in ex.Errors)
                        {
                            errors.AppendFormat("{0} (source: {1})", err.Message, err.Source);
                        }
                        string actualError = errors.ToString();

                        if (expectedError.Length > 0)
                        {
                            if (actualError.IndexOf(expectedError, StringComparison.OrdinalIgnoreCase) >= 0)
                            {
                                _logger.LogInformation("RESULT-ERROR PASS: {Expected}", expectedError);
                            }
                            else
                            {
                                _logger.LogWarning("RESULT-ERROR MISMATCH\n  expected [{Expected}]\n  actual   [{Actual}]", expectedError, actualError);
                                errorCount += 1;
                            }
                        }
                        else
                        {
                            _logger.LogError("ExecuteQuery OdbcException ({DriverVersion}): {Errors}", driverVersion, actualError);
                            errorCount += 1;
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Exception in executeQuery ({DriverVersion}): {Message}", driverVersion, ex.Message);

                        if (dataTable != null)
                        {
                            if (dataTable.HasErrors)
                            {
                                // Get an array of all rows with errors.
                                DataRow[] rowsInError = dataTable.GetErrors();
                                // Print the error of each column in each row.
                                for (int i = 0; i < rowsInError.Length; i++)
                                {
                                    foreach (DataColumn column in dataTable.Columns)
                                    {
                                        _logger.LogError("{Column} {Error}", column.ColumnName, rowsInError[i].GetColumnError(column));
                                    }
                                    // Clear the row errors
                                    rowsInError[i].ClearErrors();
                                }
                            }
                        }
                        errorCount += 1;
                    }

                    if (expectedError.Length > 0 && !exceptionThrown)
                    {
                        _logger.LogWarning("RESULT-ERROR: expected exception did not occur [{Expected}]", expectedError);
                        errorCount += 1;
                    }

                    Console.Out.Flush();
                    Console.Error.Flush();
                }
                else // executeNonQuery
                {
                    bool exceptionThrown = false;

                    try
                    {
                        stopwatch.Start();
                        rtnCount = command.ExecuteNonQuery();
                        if (timer) { _logger.LogInformation("TIMER: {Elapsed} returned {RowCount}", ToPrettyFormat(stopwatch.Elapsed), rtnCount); }
                        stopwatch.Stop();
                    }
                    catch (OdbcException ex)
                    {
                        exceptionThrown = true;
                        StringBuilder errors = new StringBuilder();
                        foreach (OdbcError err in ex.Errors)
                        {
                            errors.AppendFormat("{0} (source: {1})", err.Message, err.Source);
                        }
                        string actualError = errors.ToString();

                        if (expectedError.Length > 0)
                        {
                            if (actualError.IndexOf(expectedError, StringComparison.OrdinalIgnoreCase) >= 0)
                            {
                                _logger.LogInformation("RESULT-ERROR PASS: {Expected}", expectedError);
                            }
                            else
                            {
                                _logger.LogWarning("RESULT-ERROR MISMATCH\n  expected [{Expected}]\n  actual   [{Actual}]", expectedError, actualError);
                                errorCount += 1;
                            }
                        }
                        else
                        {
                            _logger.LogError("ExecuteNonQuery OdbcException ({DriverVersion}): {Errors}", driverVersion, actualError);
                            errorCount += 1;
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Exception in executeNonQuery ({DriverVersion}): {Message}", driverVersion, ex.Message);
                        errorCount += 1;
                    }

                    if (expectedError.Length > 0 && !exceptionThrown)
                    {
                        _logger.LogWarning("RESULT-ERROR: expected exception did not occur [{Expected}]", expectedError);
                        errorCount += 1;
                    }

                    Console.Out.Flush();
                    Console.Error.Flush();
                }
            }
            catch (OdbcException ex)
            {
                StringBuilder errors = new StringBuilder();
                foreach (OdbcError err in ex.Errors)
                {
                    errors.AppendFormat("{0} (source: {1})", err.Message, err.Source);
                }
                _logger.LogError("OdbcException ({DriverVersion}): {Errors}", driverVersion, errors.ToString());
                errorCount += 1;
            }
            catch (OverflowException ex)
            {
                _logger.LogError(ex, "OverflowException ({DriverVersion}): {Message}", driverVersion, ex.Message);
                errorCount += 1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception ({DriverVersion}): {Message}", driverVersion, ex.Message);
                errorCount += 1;
            }
            return (rtnCount, string.Empty);
        }

        //**********************************************************************
        // Returns index of first differing character, or len if strings match up to min length but lengths differ, or -2 if identical.
        public static int FirstDiff(string a, string b)
        {
            int len = Math.Min(a.Length, b.Length);
            for (int i = 0; i < len; i++)
                if (a[i] != b[i]) return i;
            return a.Length == b.Length ? -2 : len;
        }

        // Returns ±context chars around idx, with non-printable chars shown as \xNN.
        public static string StringContext(string s, int idx, int context)
        {
            int start = Math.Max(0, idx - context);
            int end = Math.Min(s.Length, idx + context + 1);
            var sb = new StringBuilder();
            for (int i = start; i < end; i++)
            {
                char c = s[i];
                if (i == idx) sb.Append(">>>");
                if (c < 0x20 || c == 0x7F)
                    sb.Append($"\\x{(int)c:X2}");
                else
                    sb.Append(c);
                if (i == idx) sb.Append("<<<");
            }
            return sb.ToString();
        }

        //**********************************************************************
        public static string ToPrettyFormat(TimeSpan span)
        {
            if (span == TimeSpan.Zero) return "0 minutes";

            var sb = new StringBuilder();
            if (span.Days > 0)
                sb.AppendFormat("{0} day{1} ", span.Days, span.Days > 1 ? "s" : String.Empty);
            if (span.Hours > 0)
                sb.AppendFormat("{0} hour{1} ", span.Hours, span.Hours > 1 ? "s" : String.Empty);
            if (span.Minutes > 0)
                sb.AppendFormat("{0} minute{1} ", span.Minutes, span.Minutes > 1 ? "s" : String.Empty);
            if (span.Seconds > 0)
                sb.AppendFormat("{0} second{1} ", span.Seconds, span.Seconds > 1 ? "s" : String.Empty);
            if (span.Milliseconds > 0)
                sb.AppendFormat("{0} millisecond{1} ", span.Milliseconds, span.Milliseconds > 1 ? "s" : String.Empty);
            return sb.ToString();

        }

    }

}
