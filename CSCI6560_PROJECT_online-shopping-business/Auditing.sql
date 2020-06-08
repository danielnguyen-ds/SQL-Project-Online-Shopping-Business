/*
- CSCI-6560 - FINAL PROJECT
- File name:	Auditing.sql
- Written by:	Daniel Nguyen
- Date:			04/10/2019
- Description: this file contains contains SQL Statements
					 to track all changes and audit sessions.
*/



/********************************
	USING DATABASE
*********************************/
use CSCI6560_Project
go



/***********************************************************************
	Using DML Trigger For Auditing Data Modification on Product table
************************************************************************/

---------------------------
-- Table Product_Audit
---------------------------
--	contains all changes made to Product table, 
--		including information of the user who makes the change and data
--		 before and after the change. 
BEGIN TRY
	DROP table Product_Audit
END TRY BEGIN CATCH END CATCH;
GO

create table Product_Audit (
	Event_Time DATETIME,
	LoginName VARCHAR(50),
	UserName VARCHAR(50),
	Instruction_type VARCHAR(50),
	Statement NVARCHAR(max),
	
	Product_ID VARCHAR(50) ,
	Old_Name VARCHAR(50),
	New_Name VARCHAR(50),
	Old_Quantity INT,
	New_Quantity INT,
	Old_Description VARCHAR(50),
	New_Description VARCHAR(50),
	Old_CostPrice VARCHAR(200),
	New_CostPrice VARCHAR(200),
	Old_SalesPrice DECIMAL(10,2),
	New_SalesPrice DECIMAL(10,2),
	Old_Discount DECIMAL(4,2), 	
	New_Discount DECIMAL(4,2),
	
	--Primary key (Event_Time,Instruction_type,New_CostPrice)
);
GO

--------------------------------
-- Trigger trig_Product_Audit 
--------------------------------
--	insert all changes made to Product table into Product_Audit table
CREATE TRIGGER trig_Product_Audit 
ON Product
AFTER INSERT, UPDATE, DELETE 
AS BEGIN 
IF @@ROWCOUNT = 0 RETURN 

DECLARE @TEMP TABLE (EventType NVARCHAR(30), Parameters INT, EventInfo NVARCHAR(max)); 
INSERT INTO @TEMP EXEC('DBCC INPUTBUFFER(@@SPID)'); 

INSERT INTO Product_Audit (
	Event_Time,
	LoginName,
	UserName,
	Instruction_type,
	Statement,
	
	Product_ID,
	Old_Name,
	New_Name,
	Old_Quantity,
	New_Quantity,
	Old_Description,
	New_Description,
	Old_CostPrice,
	New_CostPrice,
	Old_SalesPrice,
	New_SalesPrice,
	Old_Discount, 	
	New_Discount
)

SELECT
  
SYSDATETIME(), 
SUSER_SNAME(), 
USER_NAME(),

-- InstructionType
CASE 
	WHEN old.Product_ID IS NULL THEN 'INSERT' 
	WHEN new.Product_ID IS NULL THEN 'DELETE' 
	ELSE 'UPDATE' 
END,

-- statement
(SELECT EventInfo FROM @TEMP) as Statement, 

-- changed data
old.Product_ID, 
old.Name,
new.Name, 
old.Quantity,
new.Quantity, 
old.Description,	
new.Description, 
old.Cost_Price,
new.Cost_Price, 
old.Sales_Price,	
new.Sales_Price, 
old.Discount,
new.Discount

FROM deleted as old FULL JOIN inserted as new 
	ON old.Product_ID = new.Product_ID
END;
GO



/******************************
	CREATE A SQL SERVER AUDIT
*******************************/
use master
go 

--Create a new server audit
BEGIN TRY
    ALTER SERVER AUDIT TotalAudit
    WITH (STATE = OFF);
END TRY BEGIN CATCH END CATCH;
GO

BEGIN TRY
    DROP SERVER AUDIT TotalAudit;
END TRY BEGIN CATCH END CATCH;
GO

CREATE SERVER AUDIT TotalAudit
	TO FILE
	( FILEPATH = N'/var/opt/mssql/data/'	-- for Docker on my Mac
	-- FILEPATH = N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016ENT\MSSQL\Log' for my WINDOWS
	,MAXSIZE = 0 MB
	,MAX_ROLLOVER_FILES = 2147483647
	,RESERVE_DISK_SPACE = OFF
	)
	WITH
	( QUEUE_DELAY = 1000
  	,ON_FAILURE = CONTINUE
	)
GO

--Enable the audit
ALTER SERVER AUDIT TotalAudit WITH (STATE = ON);
GO



/*****************************************
	CREATE A SERVER AUDIT SPECIFICATION
******************************************/
BEGIN TRY
    ALTER SERVER AUDIT SPECIFICATION SAS_TotalAudit
    WITH (STATE = OFF);
END TRY BEGIN CATCH END CATCH;
GO

BEGIN TRY
    DROP SERVER AUDIT SPECIFICATION SAS_TotalAudit;
END TRY BEGIN CATCH END CATCH;
GO

CREATE SERVER AUDIT SPECIFICATION SAS_TotalAudit
FOR SERVER AUDIT TotalAudit

	-- a principal tried to log on to SQL Server and failed.
	ADD (FAILED_LOGIN_GROUP),

	-- a principal has successfully logged in to SQL Server
	ADD (SUCCESSFUL_LOGIN_GROUP),
	
	-- a principal has logged out of SQL Server
	 ADD (LOGOUT_GROUP)
	
	-- Enable the Server Audit Specification
	WITH (STATE = ON);
GO



/*****************************************
	CREATE A DATABASE AUDIT SPECIFICATION
******************************************/
use CSCI6560_Project
go

BEGIN TRY
    ALTER DATABASE AUDIT SPECIFICATION DAS_TotalAudit
    WITH (STATE = OFF);
END TRY BEGIN CATCH END CATCH;
GO

BEGIN TRY
    DROP DATABASE AUDIT SPECIFICATION DAS_TotalAudit;
END TRY BEGIN CATCH END CATCH;
GO

CREATE DATABASE AUDIT SPECIFICATION DAS_TotalAudit
  FOR SERVER AUDIT TotalAudit
	
	-- Track any permission changes by GRANT/REVOKE/DENY statements
	ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP)

  WITH (STATE = ON);
GO







/***********************************
		AUDIT TESTINGS
************************************/

/*------------------------------------------------------------------
	Track changes made to the product table, 
		including information of the user who 
			makes the change and data before and after the change
--------------------------------------------------------------------*/
select * from Product_Audit
order by Event_time desc
GO



/*------------------------------------------------------------------
	Track any permission changes by GRANT/REVOKE/DENY statements.
------------------------------------------------------------------*/
select
	event_time
    , CONVERT(datetime, 
        SWITCHOFFSET(CONVERT(datetimeoffset, event_time), 
            DATENAME(TzOffset, SYSDATETIMEOFFSET()))) 
       AS actual_time
	, action_id 
	, succeeded
	, server_principal_name 
	, database_principal_name
	, target_database_principal_name
	, object_name    
	, statement
	, transaction_id
	, audit_file_offset
	, file_name	
	    FROM sys.fn_get_audit_file( N'/var/opt/mssql/data/TotalAudit*.sqlaudit',default,default)  
		where action_id IN ('G','R','D')
		order by event_time desc
go 


/*------------------------------------------------------------------
	Audit successful/failed login and logout events.
		o Retrieve all failed logins for a given user
		o Retrieve all session information for a given user. 
			For each session, list begin timestamp (from login event)
								   and end timestamp (from logout event).
------------------------------------------------------------------*/
select
	event_time
    , CONVERT(datetime, 
        SWITCHOFFSET(CONVERT(datetimeoffset, event_time), 
            DATENAME(TzOffset, SYSDATETIMEOFFSET()))) 
       AS actual_time
	, action_id 
	, succeeded
	, server_principal_name      
	, statement
	, audit_file_offset
	, file_name	
	    FROM sys.
( N'/var/opt/mssql/data/TotalAudit*.sqlaudit',default,default)  
		where action_id IN ('LGIF','LGIS','LGO')
		order by event_time desc
go






------------END--------------


