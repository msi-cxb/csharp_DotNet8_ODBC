.echo on
-- .timer on
.conn sqlite3

-- 1. Create the main table
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    price REAL NOT NULL
);

-- 2. Create the audit/history table
CREATE TABLE price_log (
    id INTEGER PRIMARY KEY,
    product_id INTEGER,
    recorded_price REAL,
    change_date DATETIME
);

-- 3. Create the trigger
CREATE TRIGGER log_initial_price AFTER INSERT ON products BEGIN
    INSERT INTO price_log (product_id, recorded_price, change_date)
    VALUES (NEW.id, NEW.price, DATETIME('now'));
END;

-- 4. Populate with data
INSERT INTO products (name, price) VALUES ('Mechanical Keyboard', 89.99);
INSERT INTO products (name, price) VALUES ('Gaming Mouse', 45.00);

-- 5. Verify the results

-- RESULT:id,name,price
-- RESULT:1,Mechanical Keyboard,89.99
-- RESULT:2,Gaming Mouse,45
SELECT * FROM products;

-- ignore change_date since it is always changing
-- RESULT:id,product_id,recorded_price
-- RESULT:1,1,89.99
-- RESULT:2,2,45
SELECT id,product_id,recorded_price FROM price_log;



