using System;
using System.Data;
using System.Data.Odbc;
using System.Diagnostics;
using System.IO;
using System.Security.Cryptography.X509Certificates;
using System.Text;


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

        //**********************************************************************
        static int Main(string[] args)
        {
            Int32 rtn = -1;

            Console.WriteLine($"full path to executable --> {appPath}");

            if (args.Length == 4) 
            {
                dbFolder = args[0];
                dbFolder = Path.GetFullPath(dbFolder);
                Directory.CreateDirectory(dbFolder);
                Console.WriteLine($"dbFolder --> {dbFolder}");

                dbFile = args[1];
                if(dbFile == ":memory:")
                {
                    Console.WriteLine($"dbFile --> {dbFile}");
                }
                else
                {
                    dbFile = Path.GetFullPath(dbFile);
                    Console.WriteLine($"dbFile --> {dbFile}");
                }

                dataFolder = args[2];
                dataFolder = Path.GetFullPath(dataFolder);
                Directory.CreateDirectory(dataFolder);
                Console.WriteLine($"dataFolder --> {dataFolder}");

                sqlFileSpec = args[3];
                sqlFileSpec = Path.GetFullPath(sqlFileSpec);
                Console.WriteLine($"sqlFileSpec --> {sqlFileSpec}");

                rtn = ProcessFiles(sqlFileSpec);
            }
            else
            {
                Console.WriteLine(@"usage: csharp_DotNet8_ODBC.exe [database folder] [database file] [data folder] [sql file glob]");
                Console.WriteLine(@"hint: use full path or relative path (e.g. '.\filename') for file names, file globbing using '*' supported.");
            }

            // pause so we can see the output from the debug.writeline()
            if (Debugger.IsAttached)
            {
                Console.WriteLine("Press any key to continue...");
                Console.ReadKey();
            }

            return rtn;
        }

        ///////////////////////////////////////////////////
        public static Int32 ProcessFiles(string sqlFileSpec)
        {
            string p = Path.GetFullPath(Path.GetDirectoryName(sqlFileSpec));
            string f = Path.GetFileName(sqlFileSpec);

            var files = Directory.GetFiles(p,f);

            if (files.Length > 0)
            {
                foreach (string file in files)
                {
                    Console.WriteLine($"\n\n***************************************************\nprocessing {file}...");
                    ProcessFile(file);
                }
            }
            else
            {
                Console.WriteLine($"no sql files found. ");
            }

            return 0;
        }

        ///////////////////////////////////////////////////
        public static Int32 ProcessFile(string file)
        {
            // assumes we do not have .conn yet...every file needs this
            Boolean bHaveConnStr = false;

            try
            {
                MyOdbcClass o = new MyOdbcClass();
                string query = string.Empty;
                string expected = string.Empty;


                (Int64 AffectedRecords, String DataTableString) rtn;

                UInt64 ctr = 0;
                List<string> sqlLines = new List<string>();

                foreach (string line in File.ReadLines(file))
                {
                    // not an empty line
                    if ( (line.Trim().Length > 0) )
                    {
                        ctr++;

                        // we are using pipe to separate lines
                        if(line.StartsWith(".") || line.StartsWith("--"))
                        {
                            // process the .conn early as the entire file will be run with this connection
                            // then we don't need to add the .conn to the sql we will process later
                            if(line.TrimStart().StartsWith(".conn", StringComparison.OrdinalIgnoreCase))
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
                                        Console.WriteLine($"***** Deleted {dbFile}");
                                        File.Delete(dbFile);
                                    }
                                }

                                Console.WriteLine($"bHaveConnStr {bHaveConnStr} --> *** {dbType} *** {dbFile}");
                            }
                            else 
                            { 
                                // sqlite3 dot commands and single line comments
                                sqlLines.Add(line + "||||");
                            }

                        }
                        else if( !line.TrimEnd().EndsWith(";") )
                        {
                            // for multi line sql statements
                            sqlLines.Add(line + " ");
                        }
                        else
                        {
                            // single line sql statements
                            sqlLines.Add(line + "||||");
                        }
                    }
                }

                // create array of single line sql statements from the input sql file, comments and dot commands
                string[] sql = String.Join("", sqlLines.ToArray()).Split("||||");

                if (bHaveConnStr)
                {
                    // the entire sql file is run with a single connection
                    using (o.connection = new OdbcConnection(o.connStr))
                    {
                        o.connection.Open();
                        foreach (string line in sql)
                        {
                            //Console.WriteLine($">>>>>{line.Length} {line}");
                            if (line.TrimStart().StartsWith(".quit", StringComparison.OrdinalIgnoreCase))
                            {
                                System.Environment.Exit(1);
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
                                expected += line.TrimStart().Replace("-- RESULT:", "");
                            }
                            else if (line.TrimStart().StartsWith(".print", StringComparison.OrdinalIgnoreCase))
                            {
                                var p = line.Replace(".print", "").Trim();
                                p = p.Replace("[[__DATAFOLDER__]]", dataFolder);
                                p = p.Replace("[[__DBFOLDER__]]", dbFolder);
                                Console.WriteLine($"PRINT: {p}");
                            }
                            else if (line.TrimStart().StartsWith(".system", StringComparison.OrdinalIgnoreCase))
                            {
                                var c = line.Replace(".system", "").Trim();
                                c = c.Replace("[[__DATAFOLDER__]]", dataFolder);
                                c = c.Replace("[[__DBFOLDER__]]", dbFolder);
                                Console.WriteLine($"SYSTEM: {c}");
                                System.Diagnostics.Process process = new System.Diagnostics.Process();
                                System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo();
                                startInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                                startInfo.FileName = "cmd.exe";
                                startInfo.Arguments = "/C " + c;
                                process.StartInfo = startInfo;
                                process.Start();
                            }
                            else if (!line.TrimStart().StartsWith(".") && !line.TrimStart().StartsWith("--") && line.TrimStart().Length > 0)
                            {
                                // if we got here then we have a sql statement
                                string sqlstr = line.Trim();

                                sqlstr = sqlstr.Replace("[[__DATAFOLDER__]]", dataFolder);
                                sqlstr = sqlstr.Replace("[[__DBFOLDER__]]", dbFolder);

                                // find the sql statements that require ExecuteQuery
                                // bool executeQuery = new string[] { "select", "explain", "pragma" }.Any(s => sqlstr.IndexOf(s, StringComparison.OrdinalIgnoreCase) >= 0);
                                bool executeNonQuery = new string[] {
                                    "attach", 
                                    "begin",
                                    "commit", 
                                    "copy", 
                                    "create", 
                                    "drop", 
                                    "insert", 
                                    "install",
                                    "load",
                                    "rollback",
                                    "set",
                                    "use"
                                }.Any(s => sqlstr.StartsWith(s, StringComparison.OrdinalIgnoreCase) == true);

                                o.Execute(sqlstr, !executeNonQuery, expected);
                                expected = string.Empty;
                            }                        
                        }
                        Console.WriteLine($"\nComplete. Error count: {o.errorCount}");
                    }
                }
                else
                {
                    Console.WriteLine($".conn was not provided...please update file to include .conn [duckdb|sqlite3].");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\nMain() Exception: {ex.Message}\n\n{ex.StackTrace} \n");
                return -1;
            }
            finally
            {
                //if (System.Diagnostics.Debugger.IsAttached == true)
                //{
                //    Console.Write("press any key to continue...");
                //    Console.ReadKey();
                //}
            }
            return 0;
        }
    }


    //**********************************************************************
    public class MyOdbcClass
    {
        public string _dbType = "";
        public string connStr = "";
        public OdbcConnection connection = null;
        public Boolean echo = false;
        public Boolean timer = false;

        public Int64 errorCount = 0;


        public Boolean GetConnectionString(string dbType, string dbPath)
        {
            Boolean rtnVal = true;
            _dbType = dbType;

            switch (dbType)
            {
                case "sqlite3":
                    connStr = @"driver=SQLite3 ODBC Driver;NoWCHAR=1;database=" + dbPath + @";";
                    break;
                case "duckdb":
                    connStr = @"Driver=DuckDB Driver;Database=" + dbPath + ";allow_unsigned_extensions=true;";
                    break;
                default:
                    Console.WriteLine("unknown dbType!");
                    rtnVal = false;
                    break;
            }

            if(dbPath != ":memory:")
            {
                FileInfo fi = new FileInfo(dbPath);
                string extension = fi.Extension.ToLower();

                if (fi.Exists == false)
                {
                    Console.WriteLine($"file does not exist! creating {dbPath}");
                }
            }

            return rtnVal;
        }

        public (Int64 AffectedRecords, String DataTableString) Execute(string query, Boolean executeQuery, string expected)
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
                    Console.WriteLine($"{executeQuery} query --> {query}"); 
                }

                if (executeQuery == true)
                {
                    Int64 rowCnt = 0;
                    Int64 columnCnt = 0;

                    try
                    {
                        stopwatch.Start();
                        OdbcDataReader reader = command.ExecuteReader();
                        if (timer) { Console.WriteLine($"TIMER: {ToPrettyFormat(stopwatch.Elapsed)}"); }

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
                            Console.WriteLine($"RESULT:{s}");
                            result += s;

                            while (reader.Read())
                            {
                                rowCnt += 1;
                                s = string.Empty;
                                for (int i = 0; i < reader.FieldCount; i++)
                                {
                                    //Console.WriteLine($"reader[i].GetType().ToString() {reader[i].GetType().ToString()}");

                                    if (reader.IsDBNull(i))
                                    {
                                        s += "null";
                                    }
                                    else
                                    {
                                        switch (reader[i].GetType().ToString())
                                        {
                                            case "System.String":
                                                s += reader.GetString(i);
                                                break;
                                            case "System.Double":
                                                s += ((System.Double)reader[i]).ToString();
                                                break;
                                            case "System.Byte":
                                                s += ((System.Byte)reader[i]).ToString();
                                                break;
                                            case "System.Byte[]":
                                                s += (Encoding.Default.GetString((System.Byte[])reader[i]));
                                                break;
                                            case "System.Int16":
                                                s += ((System.Int16)reader[i]).ToString();
                                                break;
                                            case "System.Int32":
                                                s += ((System.Int32)reader[i]).ToString();
                                                break;
                                            case "System.Int64":
                                                s += ((System.Int64)reader[i]).ToString();
                                                break;
                                            case "System.Decimal":
                                                s += ((System.Decimal)reader[i]).ToString();
                                                break;
                                            case "System.TimeSpan":
                                                s += ((System.TimeSpan)reader[i]).ToString("c");
                                                break;
                                            case "System.DateTime":
                                                s += ((System.DateTime)reader[i]).ToString("yyyyMMddhhmmss");
                                                break;
                                            default:
                                                Console.WriteLine($"\n****** unhandled type ********* {reader[i].GetType()}\n");
                                                break;
                                        }
                                    }
                                    if (i < (reader.FieldCount-1))
                                    {
                                        s += ",";
                                    }
                                }
                                Console.WriteLine($"RESULT:{s}");
                                result += s;
                            }
                        }

                        // Console.WriteLine($"CHECK result {result.Length} expected {expected.Length}");
                        if (expected.Length > 0)
                        {
                            if (String.Compare(result, expected)!= 0)
                            {
                                Console.WriteLine($"RESULTS MISMATCH!!!\n    result [{result}]\n    expect [{expected}]");
                                errorCount += 1;
                            }
                        }

                        reader.Close();
                        stopwatch.Stop();
                    }
                    catch (OdbcException ex)
                    {
                        StringBuilder errors = new StringBuilder();
                        foreach (OdbcError err in ex.Errors)
                        {
                            errors.AppendFormat("{0}\t(source: {1})", err.Message, err.Source);
                        }
                        Console.WriteLine("\nExecuteQuery OdbcException: {0}\n", errors.ToString());
                        // System.Environment.Exit(-1);
                        errorCount += 1;
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine("Exeception in executeQuery: " + ex.Message + "\n" + ex.StackTrace + "\n");

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
                                        Console.WriteLine(column.ColumnName + " " + rowsInError[i].GetColumnError(column));
                                    }
                                    // Clear the row errors
                                    rowsInError[i].ClearErrors();
                                }
                            }
                        }
                        System.Environment.Exit(-1);
                    }
                    Console.Out.Flush();
                    Console.Error.Flush();
                }
                else // executeNonQuery
                {
                    try
                    {
                        stopwatch.Start();
                        rtnCount = command.ExecuteNonQuery();
                        if (timer) { Console.WriteLine($"TIMER: {ToPrettyFormat(stopwatch.Elapsed)} returned {rtnCount}"); }
                        stopwatch.Stop();
                    }
                    catch (OdbcException ex)
                    {
                        StringBuilder errors = new StringBuilder();
                        foreach (OdbcError err in ex.Errors)
                        {
                            errors.AppendFormat("{0}\t(source: {1})", err.Message, err.Source);
                        }
                        Console.WriteLine("\nExecuteNonQuery OdbcException: {0}\n", errors.ToString());
                        //System.Environment.Exit(-1);
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine("Exeception in ExecuteNonQuery: " + ex.Message + "\n" + ex.StackTrace + "\n");
                        System.Environment.Exit(-1);
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
                    errors.AppendFormat("{0}\t(source: {1})", err.Message, err.Source);
                }
                Console.WriteLine("\nOdbcException: {0}\n", errors.ToString());
                System.Environment.Exit(-1);
            }
            catch (OverflowException ex)
            {
                Console.WriteLine("\nOverflowException: Message: " + ex.Message + "\nInnerException: " + ex.InnerException + "\nStackTrace: " + ex.StackTrace + "\n");
                System.Environment.Exit(-1);
            }
            catch (Exception ex)
            {
                Console.WriteLine("\nException: " + ex.Message + " " + ex.StackTrace + "\n");
                System.Environment.Exit(-1);
            }
            return (rtnCount, string.Empty);
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
