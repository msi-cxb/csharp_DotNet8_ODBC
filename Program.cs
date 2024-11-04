using System.Data;
using System.Data.Odbc;
using System.Diagnostics;
using System.Text;

namespace csharpOdbcExample
{
    class Program
    {
        //**********************************************************************
        static int Main(string[] args)
        {
            try
            {
                MyOdbcClass o = new MyOdbcClass();
                string query = string.Empty;

                Boolean bHaveConnStr = o.GetConnectionString(@"sqlite", @".\test.db");

                Console.WriteLine($"starting... bHaveConnStr {bHaveConnStr}");

                if (bHaveConnStr)
                {
                    (Int64 AffectedRecords, String DataTableString) rtn;

                    using (o.connection = new OdbcConnection(o.connStr))
                    {
                        o.connection.Open();

                        query = @"drop table if exists company;";
                        rtn = o.Execute(query, false);

                        query = @"
CREATE TABLE COMPANY(
    ID INT PRIMARY KEY     NOT NULL,
    NAME           TEXT    NOT NULL,
    AGE            INT     NOT NULL,
    ADDRESS        CHAR(50),
    SALARY         REAL
);";
                        rtn = o.Execute(query, false);
                        query = @"
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(1, 'Paul', 32, 'California', 20000.00);
";
                        rtn = o.Execute(query, false);

                        query = @"
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(2, 'Allen', 25, 'Texas', 15000.00);
";
                        rtn = o.Execute(query, false);

                        query = @"
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(3, 'Teddy', 23, 'Norway', 20000.00);
";
                        rtn = o.Execute(query, false);

                        query = @"
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(4, 'Mark', 25, 'Rich-Mond ', 65000.00);
";
                        rtn = o.Execute(query, false);

                        query = @"
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(5, 'David', 27, 'Texas', 85000.00);
";
                        rtn = o.Execute(query, false);

                        query = @"
INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
VALUES(6, 'Kim', 22, 'South-Hall', 45000.00);
";
                        rtn = o.Execute(query, false);

                        query = @"select * from company;";
                        rtn = o.Execute(query, true);

                        o.connection.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\nMain() Exception: {ex.Message} {ex.StackTrace} \n");
                return -1;
            }
            finally
            {
                if (System.Diagnostics.Debugger.IsAttached == false)
                {
                    Console.Write("press any key to continue...");
                    Console.ReadKey();
                }
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

        public Boolean GetConnectionString(string dbType, string dbPath)
        {
            string dbExtensionStr = "";
            Boolean rtnVal = true;
            _dbType = dbType;

            switch (dbType)
            {
                case "sqlite":
                    connStr = @"driver=SQLite3 ODBC Driver;NoWCHAR=1;database=" + dbPath + @";";
                    dbExtensionStr = ".sqlite3";
                    break;
                case "db":
                    connStr = @"driver=SQLite3 ODBC Driver;NoWCHAR=1;database=" + dbPath + @";";
                    dbExtensionStr = ".db";
                    break;
                default:
                    Console.WriteLine("unknown dbType!");
                    rtnVal = false;
                    break;
            }

            FileInfo fi = new FileInfo(dbPath);
            string extension = fi.Extension.ToLower();

            if (fi.Exists == false)
            {
                Console.WriteLine($"file does not exist! creating {dbPath}");
            }

            return rtnVal;
        }

        public (Int64 AffectedRecords, String DataTableString) Execute(string query, Boolean multi)
        {
            Int64 rtnCount = -999;
            Stopwatch stopwatch = new Stopwatch();
            TimeSpan timeSpan;
            DataSet dataSet = new DataSet();
            DataTable dataTable = null;

            try
            {
                OdbcCommand command = new OdbcCommand(query, connection);
                Console.WriteLine($"state {connection.State} src [{connection.DataSource}] <-- {connection.ConnectionString}");
                Console.WriteLine($"query {query}");

                if (multi)
                {
                    Int64 rowCnt = 0;
                    Int64 columnCnt = 0;

                    try
                    {
                        stopwatch.Start();
                        OdbcDataReader reader = command.ExecuteReader();
                        Console.WriteLine($"Reader Start       {ToPrettyFormat(stopwatch.Elapsed)}");

                        if (reader.HasRows)
                        {
                            while (reader.Read())
                            {
                                rowCnt += 1;
                                string s = string.Empty;
                                for (int i = 0; i < reader.FieldCount; i++)
                                {
                                    s += reader.GetString(i) + ",";
                                }
                                Console.WriteLine($"    {rowCnt} {s}");
                            }
                        }

                        Console.WriteLine($"Reader Finish       {ToPrettyFormat(stopwatch.Elapsed)} rowCnt {rowCnt}");
                        reader.Close();
                        stopwatch.Stop();
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine("Exeception in Execute: " + ex.Message + "\n" + ex.StackTrace + "\n");

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
                    }
                }
                else
                {
                    rtnCount = command.ExecuteNonQuery();
                    Console.WriteLine($"ExecuteNonQuery returned {rtnCount}");
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
            }
            catch (OverflowException ex)
            {
                Console.WriteLine("\nOverflowException: Message: " + ex.Message + "\nInnerException: " + ex.InnerException + "\nStackTrace: " + ex.StackTrace + "\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("\nException: " + ex.Message + " " + ex.StackTrace + "\n");
                throw;
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
