.echo on
-- .timer on
.conn sqlite3

-- I gave AI the text string and asked it to parse in sqlite3 with only sql. 

-- Create the table
CREATE TABLE data_store (
    id INTEGER PRIMARY KEY,
    raw_content TEXT
);

-- Insert your example string
INSERT INTO data_store (raw_content) 
VALUES ('- PRELIMINARY   <//><//>- CATEGORY [P]  <//>------------<//>NMM <//><//>- PROPULSION [P]<//>------------<//>NO STATEMENT<//><//>- GROUP [P] <//>------------<//>BT  <//><//>- TYPE [P]  <//>------------<//>NO STATEMENT<//><//>');

-- make sure string made it successfully
-- RESULT:id,raw_content
-- RESULT:1,- PRELIMINARY   <//><//>- CATEGORY [P]  <//>------------<//>NMM <//><//>- PROPULSION [P]<//>------------<//>NO STATEMENT<//><//>- GROUP [P] <//>------------<//>BT  <//><//>- TYPE [P]  <//>------------<//>NO STATEMENT<//><//>
SELECT * FROM data_store;

-- RESULT:key_name,value_data
-- RESULT:CATEGORY,NMM
-- RESULT:PROPULSION,NO STATEMENT
-- RESULT:GROUP,BT
-- RESULT:TYPE,NO STATEMENT
WITH RECURSIVE
  split_blocks(block, remainder) AS (
    SELECT 
      SUBSTR(raw_content, 1, INSTR(raw_content, '<//><//>') - 1),
      SUBSTR(raw_content, INSTR(raw_content, '<//><//>') + 8)
    FROM data_store
    UNION ALL
    SELECT 
      SUBSTR(remainder, 1, INSTR(remainder, '<//><//>') - 1),
      SUBSTR(remainder, INSTR(remainder, '<//><//>') + 8)
    FROM split_blocks
    WHERE remainder LIKE '%<//><//>%'
  ),
  final_parse AS (
    SELECT
      TRIM(REPLACE(REPLACE(SUBSTR(block, 1, INSTR(block, '<//>------------<//>') - 1), '- ', ''), ' [P]', '')) AS key_name,
      TRIM(SUBSTR(block, INSTR(block, '<//>------------<//>') + 20)) AS value_data
    FROM split_blocks
    WHERE block LIKE '%<//>------------<//>%'
  )
SELECT key_name, value_data FROM final_parse;
