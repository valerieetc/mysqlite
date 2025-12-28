# Welcome to My Sqlite
***

## Task
My Sqlite solves the task of making an sqlite simulation, complete with a CLI (command line interface).

## Description
The project contains two files: `my_sqlite_request.rb` and `my_sqlite_cli.rb`. 

- **my_sqlite_request.rb** contains a class that allows SQL-like requests to be made within Ruby code through method chaining.
- **my_sqlite_cli.rb** provides a CLI that accepts SQL requests in standard SQL format from the command line.

Both files support the following request types:
- **SELECT** (with optional JOIN ON, WHERE, ORDER BY)
- **INSERT**
- **UPDATE**
- **DELETE**

The project works with CSV-formatted data files using either `.csv` or `.db` extensions.

## Installation
- Ruby must be installed
- CSV/database files must be in the same directory as the project files

## Usage
Using my_sqlite_request.rb:
The class can be used through method chaining:
SELECT example:
request = MySqliteRequest.new('students.csv').select(['name', 'age']).where('city', 'Riga').run
INSERT example:
request = MySqliteRequest.new.insert('students.csv').values({'name' => 'John', 'age' => '20', 'city' => 'Riga'}).run
UPDATE example:
request = MySqliteRequest.new.update('students.csv').set({'age' => '21'}).where('name', 'John').run
DELETE example:
request = MySqliteRequest.new('students.csv').delete.where('name', 'John').run 
JOIN example:
request = MySqliteRequest.new('students.csv').select(['name', 'age']).join('name', 'second_table.csv', 'Student')

Run with:
```
ruby my_sqlite_request.rb
```

Using my_sqlite_cli.rb:
Before starting make sure that you have removed or commented out your requests in `my_sqlite_request.rb`.
Start the CLI by providing a database filename (.db or .csv):
```
ruby my_sqlite_cli.rb filename.csv
```
SQL request format rules:
- Requests are case-sensitive
- Each request must be a single line ending with `;`
- Use only single quotes (`'`) for string values
- Table names must match the filename without extension

Request examples:

SELECT * FROM table_name;
SELECT column1, column2 FROM table_name;
SELECT * FROM table_name WHERE column = 'value';
SELECT * FROM table_name WHERE column = 'value' ORDER BY column ASC;
SELECT * FROM table_name ORDER BY column DESC;

SELECT * FROM table_name JOIN second_table ON table_name.column1 = second_table.column2;
SELECT * FROM table_name JOIN second_table ON table_name.column1 = second_table.column2 WHERE table_name.column = 'value';
SELECT * FROM table_name JOIN second_table ON table_name.column1 = second_table.column2 ORDER BY table_name.column ASC;

Note for JOIN: Column names in SELECT support `column` syntax, but ON, WHERE, and ORDER BY clauses support `table.column` syntax.

INSERT INTO table_name VALUES ('value1', 'value2', 'value3');

UPDATE table_name SET column1 = 'value1', column2 = 'value2' WHERE column = 'value';

DELETE FROM table_name WHERE column = 'value';

To exit the CLI, type `quit`.
