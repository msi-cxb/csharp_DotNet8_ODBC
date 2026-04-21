.echo on
-- .timer on
.conn sqlite3

-- I gave AI the text string and asked it to parse in sqlite3 with only sql. 

-- Create the table
CREATE TABLE data_store (
    id INTEGER PRIMARY KEY,
    raw_content TEXT
);

CREATE TABLE parsed_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id INTEGER,
    key_name TEXT,
    value_data TEXT,
    FOREIGN KEY(source_id) REFERENCES data_store(id)
);

CREATE TRIGGER trg_auto_parse_content
AFTER INSERT ON data_store
BEGIN
    INSERT INTO parsed_data (source_id, key_name, value_data)
    WITH RECURSIVE
      split_blocks(block, remainder) AS (
        -- Start with the first block from the newly inserted row
        SELECT 
          SUBSTR(NEW.raw_content, 1, INSTR(NEW.raw_content, '<//><//>') - 1),
          SUBSTR(NEW.raw_content, INSTR(NEW.raw_content, '<//><//>') + 8)
        UNION ALL
        -- Keep splitting until the remainder is exhausted
        SELECT 
          SUBSTR(remainder, 1, INSTR(remainder, '<//><//>') - 1),
          SUBSTR(remainder, INSTR(remainder, '<//><//>') + 8)
        FROM split_blocks
        WHERE remainder LIKE '%<//><//>%'
      )
    SELECT
      NEW.id,
      -- Apply your specific cleaning rules for the key_name
      TRIM(REPLACE(REPLACE(
        SUBSTR(block, 1, INSTR(block, '<//>------------<//>') - 1), 
      '- ', ''), ' [P]', '')),
      -- Extract the value_data
      TRIM(SUBSTR(block, INSTR(block, '<//>------------<//>') + 20))
    FROM split_blocks
    WHERE block LIKE '%<//>------------<//>%';
END;

-- Insert your example string
INSERT INTO data_store (raw_content) 
VALUES ('- PRELIMINARY   <//><//>- CATEGORY [P]  <//>------------<//>NMM <//><//>- PROPULSION [P]<//>------------<//>NO STATEMENT<//><//>- GROUP [P] <//>------------<//>BT  <//><//>- TYPE [P]  <//>------------<//>NO STATEMENT<//><//>');

-- make sure string made it successfully
-- RESULT:id,raw_content
-- RESULT:1,- PRELIMINARY   <//><//>- CATEGORY [P]  <//>------------<//>NMM <//><//>- PROPULSION [P]<//>------------<//>NO STATEMENT<//><//>- GROUP [P] <//>------------<//>BT  <//><//>- TYPE [P]  <//>------------<//>NO STATEMENT<//><//>
SELECT * FROM data_store;

-- RESULT:id,source_id,key_name,value_data
-- RESULT:1,1,CATEGORY,NMM
-- RESULT:2,1,PROPULSION,NO STATEMENT
-- RESULT:3,1,GROUP,BT
-- RESULT:4,1,TYPE,NO STATEMENT
SELECT * FROM parsed_data;
