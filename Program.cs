using DotNet.Globbing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Serilog;
using Serilog.Core;
using System;
using System.Data;
using System.Data.Odbc;
using System.Diagnostics;
using System.IO;
using System.Reflection.Metadata;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using ILogger = Microsoft.Extensions.Logging.ILogger;


namespace csharpOdbcExample
{
    class Program
    {
        public static string appPath = System.Environment.ProcessPath;

        public static string dbType;
        public static string dbFolder;
        public static string dbFile;
        public static string sqlFileSpec;
        public static string dataFolder;

        public static Boolean echoInput = false;

        private const char PatternSeparator = ';';
        private const char ExclusionPrefix = '!';

        //**********************************************************************
        static int Main(string[] args)
        {
            // T005: parse optional flags and strip them from args before positional-arg check
            LogLevel? logLevelOverride = null;
            bool logFileEnabled = false;
            bool generateReport = false;
            var argList = new List<string>(args);

            for (int i = 0; i < argList.Count; i++)
            {
                if (argList[i].Equals("--log-level", StringComparison.OrdinalIgnoreCase) && i + 1 < argList.Count)
                {
                    // T006: validate --log-level value
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
                else if (argList[i].Equals("--log-file", StringComparison.OrdinalIgnoreCase))
                {
                    logFileEnabled = true;
                    argList.RemoveAt(i);
                    i--;
                }
                else if (argList[i].Equals("--report", StringComparison.OrdinalIgnoreCase))
                {
                    generateReport = true;
                    argList.RemoveAt(i);
                    i--;
                }
            }
            args = argList.ToArray();

            // T026: configure Serilog file sink when --log-file is passed
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
                    // T027: add Serilog file sink when --log-file was passed
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

                if (args.Length == 4)
                {
                    dbFolder = args[0];
                    dbFolder = Path.GetFullPath(dbFolder);
                    Directory.CreateDirectory(dbFolder);
                    logger.LogInformation("dbFolder --> {DbFolder}", dbFolder);

                    dbFile = args[1];
                    if (dbFile == ":memory:")
                    {
                        logger.LogInformation("dbFile --> {DbFile}", dbFile);
                    }
                    else
                    {
                        dbFile = Path.GetFullPath(dbFile);
                        logger.LogInformation("dbFile --> {DbFile}", dbFile);
                    }

                    dataFolder = args[2];
                    dataFolder = Path.GetFullPath(dataFolder);
                    Directory.CreateDirectory(dataFolder);
                    logger.LogInformation("dataFolder --> {DataFolder}", dataFolder);

                    sqlFileSpec = args[3];
                    logger.LogInformation("sqlFileSpec --> {SqlFileSpec}", sqlFileSpec);

                    rtn = ProcessFiles(sqlFileSpec, logger, generateReport);
                }
                else
                {
                    logger.LogInformation("usage: csharp_DotNet8_ODBC.exe [database folder] [database file] [data folder] [sql file pattern(s)] [options]");
                    logger.LogInformation("  [sql file pattern(s)]: glob pattern(s) for SQL file selection");
                    logger.LogInformation("    separate multiple patterns with ';'  e.g. *.sql;!sqlite-ext-load-*.sql");
                    logger.LogInformation("    prefix a pattern with '!' to exclude matching files");
                    logger.LogInformation("    use '**' for recursive directory matching  e.g. sql\\**\\*.sql");
                    logger.LogInformation("options:");
                    logger.LogInformation("  --log-level <level>   Set minimum log level: Trace, Debug, Information (default), Warning, Error");
                    logger.LogInformation("  --log-file            Write log output to logs/log_YYYYMMDD_HHmmss.txt");
                    logger.LogInformation("  --report              Write a markdown report to reports/report_YYYYMMDD_HHmmss.md");
                }

                return rtn;
            }
        }

        ///////////////////////////////////////////////////
        public static Int32 ProcessFiles(string sqlFileSpec, ILogger logger, bool generateReport = false)
        {
            DateTime runStart = DateTime.Now;
            var fileResults = new List<(string FileName, long ErrorCount, string DbType)>();

            var files = ResolveFileList(sqlFileSpec, logger).ToArray();

            logger.LogInformation("files to process ({Count}):", files.Length);
            foreach (string file in files)
                logger.LogInformation("  {File}", Path.GetFileName(file));

            if (files.Length > 0)
            {
                foreach (string file in files)
                {
                    logger.LogInformation("processing {File}...", file);
                    var (fileErrorCount, fileDbType) = ProcessFile(file, logger);
                    fileResults.Add((Path.GetFileName(file), fileErrorCount, fileDbType));
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
            List<(string FileName, long ErrorCount, string DbType)> results,
            DateTime runStart,
            ILogger logger)
        {
            string reportsDir = "reports";
            Directory.CreateDirectory(reportsDir);
            string reportPath = Path.Combine(reportsDir, $"report_{runStart:yyyyMMdd_HHmmss}.md");

            long totalErrors = results.Sum(r => r.ErrorCount);
            int filesWithErrors = results.Count(r => r.ErrorCount > 0);

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
                sb.AppendLine("| File | DB Type | Errors |");
                sb.AppendLine("|------|---------|--------|");
                foreach (var (fileName, errorCount, dbType) in results)
                {
                    string safeFile = fileName.Replace("|", "\\|");
                    string safeDbType = (dbType ?? string.Empty).Replace("|", "\\|");
                    if (errorCount > 0)
                        sb.AppendLine($"| **{safeFile}** | {safeDbType} | **{errorCount}** |");
                    else
                        sb.AppendLine($"| {safeFile} | {safeDbType} | {errorCount} |");
                }

                sb.AppendLine();
                sb.AppendLine("## Summary");
                sb.AppendLine();
                sb.AppendLine($"- Files processed: {results.Count}");
                sb.AppendLine($"- Files with errors: {filesWithErrors}");
                sb.AppendLine($"- Total errors: {totalErrors}");
                sb.AppendLine();
                if (totalErrors == 0)
                    sb.AppendLine("**All tests passed.**");
                else
                    sb.AppendLine($"**{filesWithErrors} file(s) failed with {totalErrors} total error(s).**");
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
                    results.Count, filesWithErrors, totalErrors);
                if (totalErrors == 0)
                    logger.LogInformation("All tests passed.");
                else
                    logger.LogWarning("{FilesWithErrors} file(s) failed with {TotalErrors} total error(s).", filesWithErrors, totalErrors);
            }
        }

        ///////////////////////////////////////////////////
        public static (long ErrorCount, string DbType) ProcessFile(string file, ILogger logger)
        {
            // assumes we do not have .conn yet...every file needs this
            Boolean bHaveConnStr = false;
            long errorCount = 0;

            try
            {
                MyOdbcClass o = new MyOdbcClass(logger);
                string query = string.Empty;
                string expected = string.Empty;
                string expectedError = string.Empty;


                (Int64 AffectedRecords, String DataTableString) rtn;

                UInt64 ctr = 0;
                List<string> sqlLines = new List<string>();
                bool inSqlStatement = false;  // true while accumulating a multi-line SQL statement
                int beginDepth = 0;           // tracks nested BEGIN...END blocks (e.g. triggers)

                foreach (string line in File.ReadLines(file))
                {
                    // not an empty line
                    if ( (line.Trim().Length > 0) )
                    {
                        ctr++;

                        string trimmed = line.Trim();
                        string trimmedLower = trimmed.ToLowerInvariant();

                        if(trimmed.StartsWith(".") || trimmed.StartsWith("--"))
                        {
                            // process the .conn early as the entire file will be run with this connection
                            // then we don't need to add the .conn to the sql we will process later
                            if(trimmed.StartsWith(".conn", StringComparison.OrdinalIgnoreCase))
                            {
                                dbType = line.Replace(".conn", "").Trim();

                                if (dbFile == ":memory:")
                                {
                                    bHaveConnStr = o.GetConnectionString(dbType, dbFile);
                                }
                                else
                                {
                                    bHaveConnStr = o.GetConnectionString(dbType, dbFile);

                                    // each file we process should start with fresh empty db
                                    if (File.Exists(dbFile))
                                    {
                                        logger.LogInformation("Deleted {DbFile}", dbFile);
                                        File.Delete(dbFile);
                                    }
                                }

                                logger.LogInformation("bHaveConnStr {HaveConnStr} --> *** {DbType} *** {DbFile}", bHaveConnStr, dbType, dbFile);
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

                if (bHaveConnStr)
                {
                    // the entire sql file is run with a single connection
                    using (o.connection = new OdbcConnection(o.connStr))
                    {
                        o.connection.Open();
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
                                    if (o.sb.Length > 0)
                                    {
                                        logger.LogTrace($"outputFile {o.outputFile}");
                                        logger.LogTrace($"sb {o.sb.ToString()}");
                                        File.WriteAllText(o.outputFile, o.sb.ToString());
                                    }
                                    o.output = false;
                                    o.outputFile = string.Empty;
                                    o.sb.Clear();
                                }
                                else
                                {
                                    // .output [filename]
                                    o.output = true;
                                    o.sb.Clear();
                                    string outputArg = line.Trim().Substring(".output".Length).Trim();
                                    outputArg = outputArg.Replace("[[__DATAFOLDER__]]", dataFolder);
                                    outputArg = outputArg.Replace("[[__DBFOLDER__]]", dbFolder);
                                    var b = Path.IsPathFullyQualified(outputArg);
                                    o.outputFile = Path.GetFullPath(outputArg);
                                    if (File.Exists(o.outputFile))
                                    {
                                        File.Delete(o.outputFile);
                                    }
                                }
                                logger.LogDebug($"file output {o.output} file [{o.outputFile}]");
                            }
                            else if (line.TrimStart().StartsWith(".echo on", StringComparison.OrdinalIgnoreCase))
                            {
                                o.echo = true;
                            }
                            else if (line.TrimStart().StartsWith(".echo off", StringComparison.OrdinalIgnoreCase))
                            {
                                o.echo = false;
                            }
                            else if (line.TrimStart().StartsWith(".timer on", StringComparison.OrdinalIgnoreCase))
                            {
                                o.timer = true;
                            }
                            else if (line.TrimStart().StartsWith(".timer off", StringComparison.OrdinalIgnoreCase))
                            {
                                o.timer = false;
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

                                o.Execute(sqlstr, executeQuery, expected, expectedError);
                                //o.Execute(sqlstr, !executeNonQuery, expected);

                                expected = string.Empty;
                                expectedError = string.Empty;
                            }                        
                        }
                        errorCount = o.errorCount;
                        logger.LogInformation("Complete. Error count: {ErrorCount}", o.errorCount);
                    }
                }
                else if (string.IsNullOrEmpty(dbType))
                {
                    logger.LogError(".conn directive not found in file. Add '.conn [sqlite3|sqlite3-<ext>|duckdb]' at the top.");
                    errorCount = 1;
                }
                else
                {
                    logger.LogError("Unrecognised connection type '{DbType}'. Expected: sqlite3, sqlite3-<ext>, or duckdb.", dbType);
                    errorCount = 1;
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
