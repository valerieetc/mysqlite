# Welcome to My Sqlite
***

## Task
My Sqlite solves the task of making an sqlite simulation, complete with a CLI (command line interface).

## Description
The project contains two files - my_sqlite_request.rb and my_sqlite_cli.rb. The file my_sqlite_request.rb contains a class that allows to make several kinds of SQL-like requests within the file itself (see "Usage"). The file my_sqlite_cli.rb provides a CLI that allows to make the same kinds of SQL requests from the command line in the typical SQL format. The file parses the requests typed in by the user.<br>
The kinds of requests handled by this project are:<br>
SELECT (optional: JOIN ON, WHERE, ORDER BY)<br>
INSERT<br>
UPDATE<br>
DELETE<br>
The project is designed to work with CSV files that can have a .csv or .db extension.

## Installation
In order to run this project, Ruby needs to be installed. The CSV files that you want to work on must be placed in the same folder with the project files.

## Usage
The file my_sqlite_request.rb can be used on its own. To make a request with this file, you must write the request at the bottom of the file, outside of the rest of the code. The format is as follows: <br>


You can run it the following way: 
```
ruby my_sqlite_request.rb
```
You can run file my_sqlite_cli.rb the following way, where filename.csv must be replaced with your file name in a .csv or .db format:
```
ruby my_sqlite_cli.rb filename.csv
```
Once the file is running, you can enter several kinds of SQL requests: <br>
SELECT (may contain JOIN ON, WHERE, ORDER BY)<br>
INSERT<br>
UPDATE<br>
DELETE (must contain WHERE condition)<br>
The parser is case-sensitive, the request should be a single line, end with ; and contain only single quotes. The table name should match the file name without the extension.<br>
Some request examples: <br>
SELECT * FROM table_name;<br>
SELECT column1, column2 ... FROM table_name;<br>
SELECT column1, column2 ... FROM table_name WHERE column = 'value';<br>
SELECT column1, column2 ... FROM table_name WHERE column = 'value' ORDER BY column ASC|DESC; <br>
For ORDER BY you can omit ASC for ascending, but must include DESC for descending.<br>
SELECT column1, column2 ... FROM table_name JOIN second_table ON column1.table_name = column2.second_table; <br>
For JOIN requests the selection column names must be provided without specifying the table. A JOIN request can be followed by WHERE and/or ORDER BY: <br>
SELECT column1, column2 ... FROM table_name JOIN second_table ON column1.table_name = column2.second_table WHERE column.table_name = 'value' ORDER BY column.table_name ASC|DESC; <br>
INSERT INTO table_name VALUES (value1, value2, value3);<br>
UPDATE table_name SET column1 = 'value1', column2 = 'value2'... WHERE column = 'value';<br>
DELETE FROM table_name WHERE column = 'value';<br>




