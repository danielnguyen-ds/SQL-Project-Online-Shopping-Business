/*
- File name:	Permission.sql
- Written by:	Daniel Nguyen
- Date:			03/10/2019
- Description: this file contains SQL statements to create users/logins/roles
					 and statements to grant/deny/revoke permissions.
*/




/********************************
	USING DATABASE
*********************************/
USE CSCI6560_Project;
go
--select * from sys.database_principals
--select 'drop login ' + name from sys.server_principals where principal_id > 270

/**********************************
	LOGINS and USERS
**********************************/

CREATE LOGIN alebbern7L WITH PASSWORD='@123abcABC123';
CREATE USER alebbern7 FROM LOGIN alebbern7L;
GO

CREATE LOGIN csr_userL WITH PASSWORD='@123abcABC123';
CREATE USER csr_user FROM LOGIN csr_userL;
GO

CREATE LOGIN sale_userL WITH PASSWORD='@123abcABC123';
CREATE USER sale_user FROM LOGIN sale_userL;
GO

CREATE LOGIN saleManager_userL WITH PASSWORD='@123abcABC123';
CREATE USER saleManager_user FROM LOGIN saleManager_userL;
GO

CREATE LOGIN processor_userL WITH PASSWORD='@123abcABC123';
CREATE USER processor_user FROM LOGIN processor_userL;
GO



/**********************************
	ROLE CustomerR
**********************************/
-- Create Role CustomerR
CREATE ROLE CustomerR;

-- Add an user into Role CustomerR
ALTER ROLE CustomerR ADD MEMBER alebbern7;

-- Grant permissions to Role CustomerR
grant select on vCustomer to CustomerR;
grant update on vCustomer to CustomerR;
grant select on vCreditCard to CustomerR;
grant insert on vCreditCard to CustomerR;
grant update on vCreditCard to CustomerR;
grant delete on vCreditCard to CustomerR;
grant select on vProduct to CustomerR;
grant VIEW DEFINITION ON SYMMETRIC KEY::symKeyForAll TO CustomerR;
grant control ON ASYMMETRIC KEY::asymKeyForAll TO CustomerR;

deny select, insert, update, delete on Customer to CustomerR;
deny select, insert, update, delete on CreditCard to CustomerR;
deny select, insert, update, delete on Product to CustomerR;
deny select, insert, update, delete on tblOrder  to CustomerR;
deny select, insert, update, delete on OrderItem to CustomerR;


GO



/**********************************
	ROLE CustomerServiceRepresentativeR
**********************************/

-- Create Role CustomerServiceRepresentativeR
CREATE ROLE CustomerServiceRepresentativeR;

-- Add an user into Role CustomerServiceRepresentativeR
ALTER ROLE CustomerServiceRepresentativeR ADD MEMBER csr_user;

-- Grant permissions to Role CustomerServiceRepresentativeR
grant select on vProduct to CustomerServiceRepresentativeR;
grant select on Customer to CustomerServiceRepresentativeR;
grant select on tblOrder to CustomerServiceRepresentativeR;
grant select on OrderItem to CustomerServiceRepresentativeR;
grant exec on dbo.sp_delete_from_OrderItem to CustomerServiceRepresentativeR;
grant exec on dbo.sp_update_from_OrderItem to CustomerServiceRepresentativeR;
grant exec on dbo.sp_insert_from_OrderItem to CustomerServiceRepresentativeR;

deny insert, update, delete on Customer to CustomerServiceRepresentativeR;
deny select, insert, update, delete on CreditCard to CustomerServiceRepresentativeR;
deny select, insert, update, delete on Product to CustomerServiceRepresentativeR;
deny insert, update, delete on tblOrder  to CustomerServiceRepresentativeR;
deny insert, update, delete on OrderItem to CustomerServiceRepresentativeR;
GO



/**********************************
	ROLE SaleR
**********************************/

-- Create Role SaleR
CREATE ROLE SaleR;

-- Add an user into Role SaleR
ALTER ROLE SaleR ADD MEMBER sale_user;

-- Grant permissions to Role SaleR
grant select on Product to SaleR;
grant insert on Product to SaleR;
grant exec on dbo.sp_update_from_Product to SaleR;
grant VIEW DEFINITION ON SYMMETRIC KEY::symKeyForAll TO SaleR;
grant control ON ASYMMETRIC KEY::asymKeyForAll TO SaleR;

deny select, insert, update, delete on Customer to SaleR;
deny select, insert, update, delete on CreditCard to SaleR;
deny update on Product to SaleR;
deny select, insert, update, delete on tblOrder  to SaleR;
deny select, insert, update, delete on OrderItem to SaleR;
GO



/**********************************
	ROLE SaleManagerR
**********************************/

-- Create Role SaleManagerR
CREATE ROLE SaleManagerR;

-- Add an user into Role SaleManagerR
ALTER ROLE SaleManagerR ADD MEMBER saleManager_user;

-- Grant permissions to Role SaleManagerR
grant select on Product to SaleManagerR;
grant insert on Product to SaleManagerR;
grant update on Product to SaleManagerR;
grant exec on dbo.sp_delete_from_Product to SaleManagerR;
grant VIEW DEFINITION ON SYMMETRIC KEY::symKeyForAll TO SaleManagerR;
grant control ON ASYMMETRIC KEY::asymKeyForAll TO SaleManagerR;

deny select, insert, update, delete on Customer to SaleManagerR;
deny select, insert, update, delete on CreditCard to SaleManagerR;
deny delete on Product to SaleManagerR;
deny select, insert, update, delete on tblOrder  to SaleManagerR;
deny select, insert, update, delete on OrderItem to SaleManagerR;
GO



/**********************************
	ROLE OrderProcessorR
**********************************/

-- Create Role OrderProcessorR
CREATE ROLE OrderProcessorR;

-- Add an user into Role OrderProcessorR
ALTER ROLE OrderProcessorR ADD MEMBER processor_user;

-- Grant permissions to Role OrderProcessorR
grant select on vOrder to OrderProcessorR;
grant select on vOrderItem to OrderProcessorR;
grant exec on dbo.sp_update_from_tblOrder to OrderProcessorR;

deny select, insert, update, delete on Customer to OrderProcessorR;
deny select, insert, update, delete on CreditCard to OrderProcessorR;
deny select, insert, update, delete on Product to OrderProcessorR;
deny select, insert, update, delete on tblOrder  to OrderProcessorR;
deny select, insert, update, delete on OrderItem to OrderProcessorR;
GO



------------END--------------


