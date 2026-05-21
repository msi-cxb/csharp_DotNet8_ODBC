-- https://dzone.com/articles/postgresql-random-test-data
.timer on
.conn postgresql

.print ===================== current_schema ========================
SELECT current_schema();

.print ===================== create table ========================
DROP TABLE IF EXISTS public.test_tab2;
CREATE TABLE IF NOT EXISTS public.test_tab2
(
    id BIGINT NOT NULL,
    fname VARCHAR(50),
    lname VARCHAR(50),
    create_date DATE,
    status BOOLEAN,
    CONSTRAINT test_tab1_pkey PRIMARY KEY (id)
);

.print ===================== table contents ========================
-- Non-deterministic output: no RESULT assertion
SELECT * FROM public.test_tab2 limit 1;

.print ===================== fill the table ========================
SELECT setseed(0.42);
DO $$
DECLARE
    rec_count INTEGER := 100000; -- Limit to 10 records for testing
    col RECORD;
    col_list TEXT := '';
    val_list TEXT := '';
    sql_stmt TEXT;
    i INTEGER;
    tbl_schema TEXT := 'public';
    tbl_name TEXT := 'test_tab2';
    random_date DATE;
    random_status BOOLEAN;
BEGIN
    -- Construct column names for insert statement
    FOR col IN
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = tbl_schema
          AND table_name = tbl_name
        ORDER BY ordinal_position
    LOOP
        col_list := col_list || col.column_name || ', ';
    END LOOP;

    -- Trim trailing comma from column list
    col_list := left(col_list, length(col_list) - 2);

    -- Loop to insert rows
    FOR i IN 1..rec_count LOOP
        -- Initialize val_list for each row
        val_list := '';

        -- Loop through each column type to generate corresponding values for each row
        FOR col IN
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = tbl_schema
              AND table_name = tbl_name
            ORDER BY ordinal_position
        LOOP
            -- Generate value for each column based on its data type
            CASE col.data_type
                WHEN 'bigint' THEN
                    val_list := val_list || i || ', ';
                WHEN 'character varying' THEN
                    val_list := val_list || quote_literal(col.column_name || '_' || i) || ', ';
                WHEN 'text' THEN
                    val_list := val_list || quote_literal(col.column_name || '_' || i) || ', ';
                WHEN 'date' THEN
                    -- Generate a random date between 2000-01-01 and 2009-12-31
                    random_date := '2000-01-01'::date + trunc(random() * 366 * 10)::int;
                    val_list := val_list || quote_literal(random_date) || ', ';
                WHEN 'boolean' THEN
                    -- Generate a random boolean value (TRUE/FALSE)
                    random_status := (i % 2 = 0);  -- TRUE if even, FALSE if odd
                    val_list := val_list || random_status || ', ';
                WHEN 'uuid' THEN
                    val_list := val_list || 'gen_random_uuid(), ';
                ELSE
                    val_list := val_list || 'NULL, ';
            END CASE;
        END LOOP;
        -- Trim trailing comma from val_list
        val_list := left(val_list, length(val_list) - 2);
        -- Prepare the SQL statement with dynamically generated values
        sql_stmt := format(
            'INSERT INTO %I.%I (%s) VALUES (%s);',
            tbl_schema, tbl_name,
            col_list,
            val_list
        );
        -- Print the SQL statement to the console
        RAISE NOTICE 'Executing: %', sql_stmt;
        -- Execute the SQL statement
        EXECUTE sql_stmt;
        -- Print confirmation of each inserted row
        RAISE NOTICE 'Inserted row % into %I.%I', i, tbl_schema, tbl_name;
    END LOOP;
END
$$;

.print ===================== table contents ========================
-- Non-deterministic output: no RESULT assertion
-- RESULT:cnt
-- RESULT:100000
SELECT count(1) AS cnt FROM public.test_tab2;


-- RESULT:id,fname,lname,create_date,status
-- RESULT:1,fname_1,lname_1,20070612120000,false
-- RESULT:2,fname_2,lname_2,20030819120000,true
-- RESULT:3,fname_3,lname_3,20090520120000,false
-- RESULT:4,fname_4,lname_4,20000823120000,true
-- RESULT:5,fname_5,lname_5,20001210120000,false
-- RESULT:6,fname_6,lname_6,20020221120000,true
-- RESULT:7,fname_7,lname_7,20041201120000,false
-- RESULT:8,fname_8,lname_8,20031125120000,true
-- RESULT:9,fname_9,lname_9,20051007120000,false
-- RESULT:10,fname_10,lname_10,20070722120000,true
SELECT * FROM public.test_tab2 order by id limit 10;


