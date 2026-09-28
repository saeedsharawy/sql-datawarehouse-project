/*
--------------create database and schema-------------
---purpose of the script : 

creating new database named 'datawarehouse' after checking if it exists or not .
if it exist the server will go and drop it and then create the new one .
the scripts alse creates anew schemas for each layerr in our database and they are three layers bronze ,silvr and gold

----WARNING----
dont run this script at the beging of the project if its finshed beacuse it is gonna delete the datbae with all the data stored in it 
be carefull when you are exceuting this script 
i made it only at the begging oof my project as i said to make sure of the existance as i am starting  a new datbase and i dont want it if it exists 
*/

-- Make sure we are connected to master
use master;
go
--before creating we must check the existance of database specially if you are modyfing a databasse 
--drop and recreate the database if exist 
-- Check whether the database exists
IF EXISTS
(
    SELECT 1
    FROM sys.databases
    WHERE name = 'datawarehouse'
)
BEGIN

    -- Force existing connections to close
    ALTER DATABASE datawarehouse
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    -- Drop the database
    DROP DATABASE datawarehouse;

END;
GO

-- Create the database
create database datawarehouse ;
go
--use your database
use datawarehouse ;
go 
--create schemas for each layer 
create schema bronze;
go 
create schema Silver;
go 
create schema Gold ;
go
