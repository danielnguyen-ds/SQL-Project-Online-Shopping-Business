/*
- CSCI-6560 - FINAL PROJECT
- File name:	Encrypt.sql
- Written by:	Daniel Nguyen
- Date:			03/10/2019
- Description: this file contains SQL statements to encrypt the data:
*/




/********************************
	USING DATABASE
*********************************/
use CSCI6560_Project
go



/******************
	ENCRIPTION KEYS
*******************/

-- a database master key for the databse 
CREATE MASTER KEY ENCRYPTION BY   
PASSWORD = 'CSCI6560_Project';  

-- a symmetric key protected by an asymmetric key
create asymmetric key asymKeyForAll
with algorithm = RSA_2048

create symmetric key symKeyForAll
with algorithm = AES_256
encryption by asymmetric key asymKeyForAll;
GO



/***************************************
	SUPPORTING PROCEDURE and FUNCTION 
****************************************/	

------------------------------------
-- procedure sp_EncryptingString
------------------------------------
	-- 	encripts a (varchar) value into a varchar-form,
	--		 using a symmetric + an asymmetric key
create procedure sp_EncryptingString
	@string varchar(200),
	@encryptedString varchar(200) OUTPUT
AS
	-- Open the keys
	OPEN SYMMETRIC KEY symKeyForAll
	DECRYPTION BY ASYMMETRIC KEY asymKeyForAll;
	
	-- Encrypting the string to a varbinary value
	declare @encryptedValue varbinary(200)
	SET @encryptedValue = EncryptByKey(Key_GUID('symKeyForAll'), @string );

	
	-- Converting the varbinary value to varchar form
	SELECT @encryptedString = CONVERT(varchar(200), @encryptedValue, 1); 

	-- Closes the symmetric key
	CLOSE SYMMETRIC KEY symKeyForAll;
GO


-------------------------------------
--	Fucntion: func_DecryptingString
-------------------------------------
	-- 	decripts a (varchar-form) value back to the original string 
create function func_DecryptingString ( @encripted varchar(200) )
returns varchar(200)
as
begin
	declare @decripted varchar(200);
	select @decripted =  CONVERT(varchar(200), DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('asymKeyForAll'), NULL, CONVERT(varbinary(200), @encripted, 1)));
	return @decripted;
end;
go



/************************************
	Trigger trig_EncryptingPassword
*************************************/
	-- Encrypting Customer.Password
create trigger trig_EncryptingPassword
on Customer
for insert, update
as
begin

	if Update(Password)
	begin
		declare @pk varchar(50) = (select User_ID from Inserted);
		declare @value varchar(200) = (select Password from Inserted);
		declare @encryptedString varchar(200);
		exec dbo.sp_EncryptingString @value, @encryptedString OUTPUT;
		update Customer set Password = @encryptedString where User_ID = @pk;
	
	end
end 
go	



/*********************************************
	Trigger trig_EncryptingCreditCardNumber
**********************************************/
	-- Encrypting CreditCard.Credit_Card_Nuber
create trigger trig_EncryptingCreditCardNumber
on CreditCard
for insert, update
as
begin

	if Update(Credit_Card_Number)
	begin
		declare @pk varchar(50) = (select Credit_Card_ID from Inserted);
		declare @value varchar(200) = (select Credit_Card_Number from Inserted);
		declare @encryptedString varchar(200);
		exec dbo.sp_EncryptingString @value, @encryptedString OUTPUT;
		update CreditCard set Credit_Card_Number = @encryptedString where Credit_Card_ID = @pk;
	
	end
end 
go	



/************************************************
	Trigger trig_EncryptingCostPrice_ControlCosts
************************************************/
	-- Encrypting Product.Cost_Price
	-- Ensure that Cost Price is smaller or equal to the Sales Price after discounted
create trigger trig_EncryptingCostPrice_ControlCosts
on Product
for insert, update
as
begin
		
	-- Encrypting
	if Update(Cost_Price)
	begin
		declare @pk varchar(50) = (select Product_ID from Inserted);
		declare @value varchar(200) = (select Cost_Price from Inserted);
		declare @encryptedString varchar(200);
		exec dbo.sp_EncryptingString @value, @encryptedString OUTPUT;
		update Product set Cost_Price = @encryptedString where Product_ID = @pk;
		
	end
	
	--Ensure that Cost Price is smaller or equal to the Sales Price after discounted
	If (
	(select count(P.Product_ID)
	from  Product P inner join Inserted I on P.Product_ID = I.Product_ID
	where (CAST(dbo.func_DecryptingString(P.Cost_Price) AS decimal(10,2)) - (1.0-P.Discount) * P.Sales_Price) > 0 ) > 0 )
		begin
      		RAISERROR('Error, Cost_Price CANNOT BE larger than Paid_Price. ',10,1);
      		ROLLBACK TRANSACTION;
      		RETURN;
		end	
end 
go	
	







/***********************************************************
	retrieve Product table with clear text on Cost_Price
************************************************************/
select * , dbo.func_DecryptingString(Cost_Price) as Decrypted_Cost_Price
from Product;







------------END--------------

