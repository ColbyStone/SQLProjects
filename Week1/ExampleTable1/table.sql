--create
CREATE TABLE ExampleTable1 (
    [id] INT PRIMARY KEY,
    [name] TEXT NOT NULL,
    [age] INT NOT NULL
);

--insert
INSERT INTO ExampleTable1 (id, name, age) VALUES
(1, 'Alice', 30),
(2, 'Bob', 25),
(3, 'Charlie', 35);

--fetch
SELECT * FROM ExampleTable1;