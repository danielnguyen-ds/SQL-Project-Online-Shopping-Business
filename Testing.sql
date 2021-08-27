/*
- CSCI-6560 - FINAL PROJECT
- File name:	Testing.sql
- Written by:	Daniel Nguyen
- Date:			03/10/2019
- Description: this file contains test cases to demonstrate the satisfaction
					 of all constraints and requirement as well as permission requirements.
*/



/********************************
	USING DATABASE
*********************************/
use CSCI6560_Project
go



/********************************************
	TEST ON  CUSTOMER USERS
*********************************************/

----------------------------------------------------------------------------
-- Customer can view information of all products excluding Cost_Price
----------------------------------------------------------------------------
execute as user='alebbern7';
select * from vProduct;
revert;
go


----------------------------------------------------------------------------
-- Customer can view their own information
----------------------------------------------------------------------------
execute as user='alebbern7';
select * from vCustomer;
revert;
go


----------------------------------------------------------------------------
-- Customer can view their own credit cards: last 4 digits and some other info. 
----------------------------------------------------------------------------
execute as user='alebbern7';
select * from vCreditCard;
revert;
go


----------------------------------------------------------------------------
-- Customer can update their own information on Table Customer
----------------------------------------------------------------------------

-- Successfully Updating 
execute as user='alebbern7';
select * from vCustomer; -- before
update vCustomer set 
	Email = 'alebbern7@edublogs.org_UPDATED'
	, Password = 'RJ1v3vNwpe_UPDATED'
	, Firstname = 'Artus_UPDATED'
	, Lastname = 'Lebbern_UPDATED'
	, Address = '29232 Mariners Cove Alley_UPDATED' 
	, Phone = '694-216-2805_UPDATED'; 	
select * from vCustomer;	--after
revert;

-- NOTE: updated information will be shown in the base table Customer as well
execute as user='dbo';
select * from Customer
go


----------------------
-- Unsuccessful Case:
----------------------
-- Unsuccessfully Updating (get Error Message)
-- this action is failed since User_ID cannot be changed anytime: 
execute as user='alebbern7';
update vCustomer set 
	User_ID = 'alebbern7_UPDATED' 
	, Email = 'alebbern7@edublogs.org_UPDATED'
	, Password = 'PASSWORD_UPDATED'
	, Firstname = 'Artus_UPDATED'
	, Lastname = 'Lebbern_UPDATED'
	, Address = '29232 Mariners Cove Alley_UPDATED' 
	, Phone = '694-216-2805_UPDATED'; 

-- back to dbo	
revert;
go


----------------------------------------------------------------------------
-- Customer can insert a credit card
----------------------------------------------------------------------------
execute as user='alebbern7';
select * from vCreditCard; -- before
insert into vCreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('NEW_CARD', '9999999999999999', 'Lowe MacLice_NEW', '11/4/1097', 999, '6506 Jenna Alley_NEW', 'alebbern7_NEW');   
select * from vCreditCard; -- after
revert;

-- NOTE: the new credit card will be shown in the base table CreditCard as well
execute as user='dbo';
select * from CreditCard
order by Owner_ID;


----------------------------------------------------------------------------
-- Customer can remove a credit card
----------------------------------------------------------------------------
execute as user='alebbern7';
select * from vCreditCard; -- before
delete from vCreditCard where Credit_Card_ID = 'NEW_CARD';
select * from vCreditCard; -- after
revert;


-----------------------------------------------------------------------------------------
-- Customer can only modify Holder_Name and Billing_Address of existing credit card
-----------------------------------------------------------------------------------------
 -- NOTE: ONLY Holder_Name and Billing_Address have been updated, the other updated attributes have been ignored
execute as user='alebbern7';
select * from vCreditCard; -- before
update vCreditCard set 
	Credit_Card_Number = '999999999999999999'
	, Holder_Name = 'Kim Harvison_UPDATED'
	, Expire_Date = '2999-06-19'
	, CVC_Code = '999'
	, Billing_Address = '196 Tennessee Way_UPDATED' 
	, Owner_ID = 'alebbern7_UPDATED'	
select * from vCreditCard; -- after
revert;


-- NOTE: updated credit card(s) will be shown in the base table CreditCard as well
execute as user='dbo';
select * from CreditCard
order by Owner_ID;





/********************************************
-- CUSTOMER-SERVICE-REPRESENTATIVE USERS
*********************************************/

----------------------------------------------------------------------------
-- User can view information of all products excluding Cost_Price
----------------------------------------------------------------------------
execute as user='csr_user';
select * from vProduct;
revert;


----------------------------------------------------------------------------
-- User can view customer information and orders
----------------------------------------------------------------------------
execute as user='csr_user';
select * from Customer;
select * from tblOrder;
select * from OrderItem;
revert;


-----------------------------------------------------------------------------------------------------
-- User can remove an order item from a placed order only if the order status is “in preparation”
-----------------------------------------------------------------------------------------------------

-- All order items (= 4) with the order status as “in preparation”, before the removal
select * from OrderItem where Order_ID IN (select Order_ID from tblOrder where Status ='in preparation') ;

-- removing an order item with Order_ID = '0782901' and Product_ID = 'AV-03'
execute as user='csr_user';
exec dbo.sp_delete_from_OrderItem '0782901', 'AV-03';
revert;

-- All order items (= 3) with the order status as “in preparation”, after the removal
select * from OrderItem where Order_ID IN (select Order_ID from tblOrder where Status ='in preparation') ;


----------------------
-- Unsuccessful Case:
----------------------
-- attempting to remove an order item with Order_ID = '0314338' and Product_ID = 'FI-72' 
-- however, the order status of this item is 'shipped', not 'in preparation', then this action will be ignored (Error Message)
--			select Order_ID,Status  from tblOrder where Order_ID = '0314338' ;

execute as user='csr_user';
exec dbo.sp_delete_from_OrderItem '0314338', 'FI-72';
revert;


-----------------------------------------------------------------------------------------------------
-- User can insert a new order item to a placed order only if the order status is “in preparation”
-----------------------------------------------------------------------------------------------------

-- All order items (= 3) with the order status as “in preparation”, before the insertion
select * from OrderItem where Order_ID IN (select Order_ID from tblOrder where Status ='in preparation') ;

-- inserting an order item with Order_ID = '0782901', Product_ID = 'AV-03', and Quantity = 10
execute as user='csr_user';
exec dbo.sp_insert_from_OrderItem '0782901', 'AV-03', 10;
revert;

-- All order items (= 4) with the order status as “in preparation”, after the insertion
select * from OrderItem where Order_ID IN (select Order_ID from tblOrder where Status ='in preparation') ;

----------------------
-- Unsuccessful Case:
----------------------
-- attempting to insert an order item with Order_ID = '0314338', Product_ID = 'MG-18', and Quantity = 10
-- however, the order status of this item is 'shipped', not 'in preparation', then this action will be ignored (Error Message)
--   select Order_ID,Status  from tblOrder where Order_ID = '0314338' ;

execute as user='csr_user';
exec dbo.sp_insert_from_OrderItem '0314338', 'MG-18', 10;
revert;


---------------------------------------------------------------------------------------------------------------------
-- User can update the quantity of an order item from a placed order only if the order status is “in preparation”
---------------------------------------------------------------------------------------------------------------------

-- All order items with the order status as “in preparation”, before the update
select * from OrderItem where Order_ID IN (select Order_ID from tblOrder where Status ='in preparation') ;

-- updating Quantity = 30 for an order item with Order_ID = '0782901', Product_ID = 'AV-03'
execute as user='csr_user';
exec dbo.sp_update_from_OrderItem '0782901', 'AV-03', 30;
revert;

-- All order items with the order status as “in preparation”, after the update
select * from OrderItem where Order_ID IN (select Order_ID from tblOrder where Status ='in preparation');

----------------------
-- Unsuccessful Case:
----------------------
-- attempting to update Quantity = 30 for an order item with Order_ID = '0314338', Product_ID = 'FI-72' 
-- however, the order status of this item is 'shipped', not 'in preparation', then this action will be ignored (Error Message)
--		select Order_ID,Status  from tblOrder where Order_ID = '0314338' ;

execute as user='csr_user';
exec dbo.sp_update_from_OrderItem '0314338', 'FI-72', 30;
revert;




/********************************************
		SALE USERS
*********************************************/

----------------------------------------------------------------------------
-- User can view information of all products
----------------------------------------------------------------------------
execute as user='sale_user';
select * from Product;
revert;


----------------------------------------------------------------------------
-- User can insert new product into Product table
----------------------------------------------------------------------------
execute as user='sale_user';
select * from Product; -- before
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('AA-00', 'Strawberry_NEW', 0, 'Inserted by sale_user', '9.99', 99.99, '0.10');
select * from Product; -- after
revert;


--------------------------------------------------------------------------------------
-- User can update a product from Product table, 
		-- but cannot modify Cost_Price, Sales_Price, and Discount attributes
		-- , which means he can only change Name, Quantity, and Description attributes 
--------------------------------------------------------------------------------------

-- updating Name = 'Strawberry_UPDATED', Quantity = 300, and Description = 'Youbridge_UPDATED' 
--		for product with Product_ID = 'AA-00'
execute as user='sale_user';
select * from Product; -- before
exec sp_update_from_Product 'AA-00', 'Strawberry_UPDATED', 300, 'Updated by sale_user';
select * from Product; -- after
revert;





/********************************************
-- SALE-MANAGER USERS
*********************************************/

----------------------------------------------------------------------------
-- User can view information of all products
----------------------------------------------------------------------------
execute as user='saleManager_user';
select * from Product;
revert;


----------------------------------------------------------------------------
-- User can insert new product into Product table
----------------------------------------------------------------------------
execute as user='saleManager_user';
select * from Product; -- before
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('AA-01', 'Mix Pina Colada_NEW', 0, 'Inserted by saleManager_user', '99.99', 199.99, '0.20');
select * from Product; -- after
revert;


--------------------------------------------------------------------------------------
-- User can update a product from Product table, 
		-- and can modify Cost_Price, Sales_Price, and Discount attributes
--------------------------------------------------------------------------------------

-- updating: increase Sale_Price 20%, and set Discount = 5% for all products
execute as user='saleManager_user';
select * from Product; -- before
update Product set Sales_Price = Sales_Price * 1.2, Discount = 0.05;
select * from Product; -- after
revert;

-- updating: update Cost_Price = '79.99' for the product with Product_ID = 'AA-01'
--		NOTE: After Cost_Price is updated to '79.99', it will be encrypted automatically.
execute as user='saleManager_user'; 
select * from Product where Product_ID = 'AA-01'; -- before
update Product set Cost_Price = '79.99' where Product_ID = 'AA-01';
select * from Product where Product_ID = 'AA-01'; -- before
revert;

-- NOTE: If to confirm this sensitive (encypted) Cost_Price of this product is updated,
--			ONLY the dbo can decrypt and query it (VERY RESTRICT!!!)
execute as user='dbo';
select *, dbo.func_DecryptingString(Cost_Price) as DECRYPTED_Cost_Price 
from Product where Product_ID = 'AA-01'; 



----------------------------------------------------------------------------
-- User can remove a product from database if its quantity is 0
----------------------------------------------------------------------------
execute as user='saleManager_user'; 
select * from Product; -- before
exec dbo.sp_delete_from_Product 'AA-01';
select * from Product; -- after
revert;


----------------------
-- Unsuccessful Cases:
----------------------
-- attempting to remove a product from database if its quantity is NOT 0
-- , then this action will be ignored (Error Message)
execute as user='saleManager_user'; 
exec dbo.sp_delete_from_Product 'AA-00'; --NOTE: Quantity of 'AA-00' is 300
revert;


-----------------------------------------------
-- no permissions on all other tables:
--		Customer/CreditCard/tblOrder/OrderItem
-----------------------------------------------
-- then, these followed queries are falied:
execute as user='saleManager_user'; 
select * from Customer;
select * from CreditCard;
select * from tblOrder;
select * from OrderItem;

-- back to dbo	
revert;





/********************************************
-- Order-Processor USERS
*********************************************/

----------------------------------------------------------------------------
-- User can view Order excluding Total_Amount, Credit_Card_ID attributes;
----------------------------------------------------------------------------
execute as user='processor_user';
select * from vOrder;
revert;

----------------------------------------------------------------------------
-- User	 can view OrderItem excluding PaidPrice;
----------------------------------------------------------------------------
execute as user='processor_user';
select * from vOrderItem;
revert;

----------------------------------------------------------------------------
-- User can only modify Status attribute of Order table
----------------------------------------------------------------------------
-- update Status = 'ready to ship' for the order with Order_ID = '0270223'
execute as user='processor_user';
select * from vOrder where Order_ID = '0270223';   -- before
exec dbo.sp_update_from_tblOrder '0270223', 'ready to ship';
select * from vOrder where Order_ID = '0270223';   -- after
revert;




/************************************************************
	DEMONSTRATIONS ON CONSTRAINTS & REQUIREMENTS TESTINGS
*************************************************************/

----------------------------------------------------------------------------------------------------------
--- The Cost_Price of a product is always smaller or equal to the Sales_Price of that product after Discounted
-- 			(The company will never lose money by selling a product.)
----------------------------------------------------------------------------------------------------------
-- FAILED CASES:

-- attempting to UPDATE Cost_Price/ Sales_Price/Discount to a product with Product_ID = 'AN-74'
--		 such that: 	Cost_Price > Sales_Price after Discounted, 
--		Since it violates the constraint then it's failed (Error Message):
update Product set Cost_Price = '100.00', Sales_Price = 50.00, Discount = 0.1
	where Product_ID = 'AN-74';


-- Similarly, attempting to INSERT a new product where its Cost_Price > Sales_Price after Discounted, 
--		Since it violates the constraint then it's failed (Error Message):
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('WW-11', 'BAD PRODUCT', 100, 'Unsuccessful Case', '99.99', 50.00, '0.10');


----------------------------------------------------------------------------------------------------------
--- OrderItem.PaidPrice and Order.Total_Amount should always be calculated automatically and consistent:
-- 			when Quantity of a order item is changed, its PaidPrice will be recalculated, 
--			and the Total_Amount of the order will be updated as well
----------------------------------------------------------------------------------------------------------

-- testing on the order item with Order_ID = '0270223' and Product_ID='AN-74':

-- before
select * from OrderItem where Order_ID = '0270223' and Product_ID='AN-74';
select * from tblOrder where Order_ID = '0270223';

-- updating its Quantity
update OrderItem set Quantity = 10 where Order_ID = '0270223' and Product_ID='AN-74';

-- after
select * from OrderItem where Order_ID = '0270223' and Product_ID='AN-74';
select * from tblOrder where Order_ID = '0270223';


----------------------------------------------------------------------------------------------------------
-- Start charging the credit card whenever the order status is changed to [shipped].
--		Charge can be completed by printing a formatted message
----------------------------------------------------------------------------------------------------------

-- after changing Status = 'ready to ship' to 'shipped' for the oder with Order_ID = '0270223'
-- 		a message: "Credit Card ending with #### is charged $####### for the order with order id 0270223" would be shown:

-- before
select * from tblOrder where Order_ID = '0270223';

-- updating
update tblOrder set Status = 'shipped' where Order_ID = '0270223';

-- after
select * from tblOrder where Order_ID = '0270223';


----------------------------------------------------------------------------------------------------------
-- When an order is placed, deduct OrderItem.Quantity from Product.Quantity for each order item.
----------------------------------------------------------------------------------------------------------

-- before: all products in the order with Order_ID = '0270223'
select * from Product where Product_ID in (select Product_ID from OrderItem where Order_ID = '0270223');

-- updating: change Status of the order to 'placed'
update tblOrder set Status = 'placed' where Order_ID = '0270223';

-- after: all products in the order with Order_ID = '0270223' 
		-- (Quantities of those products are expected to be decreased)
select * from Product where Product_ID in (select Product_ID from OrderItem where Order_ID = '0270223');


----------------------------------------------------------------------------------------------------------
-- When an order item is removed, add OrderItem.Quantity back to Product.Quantity.
----------------------------------------------------------------------------------------------------------

-- before
select * from Product where Product_ID='AN-74' ;

-- remove the order item with Order_ID = '0270223' and Product_ID='AN-74'
delete from OrderItem where Order_ID = '0270223' and Product_ID='AN-74';

-- after
	-- (Quantity of this product is expected to be increased)
select * from Product where Product_ID='AN-74';




----------------------------------------------------------------------------------------------------------
-- "If an order doesn’t contain order items, the order should also be removed" (the last line, page 1)
----------------------------------------------------------------------------------------------------------
-- before
select * from OrderItem;
select * from tblOrder;


-- removing ALL order iterms of the order with Order_ID = '0270223'
delete from OrderItem where Order_ID = '0270223';

-- after: (the order with Order_ID = '0270223' will then be removed from the tblOrder as well)
select * from OrderItem;
select * from tblOrder;



----------------------------------------------------------------------------------------------------------
-- No one can modify user_id
----------------------------------------------------------------------------------------------------------

--	first, we create a new customer 
--		(to neglect the involvements of any foreign key constraints)
--	and test on this one:

insert into Customer (User_ID, Email, Password, Firstname, Lastname, Address, Phone) values 
('0_test_user', 'test_user@test_user.gmail', 'test_userPass', 'Test', 'User', '11111 New Address', '123-456-7777');
select * from Customer;

-- attempting to modify user_id, but it's failed (Error Message):
update Customer set User_ID = '0_test_user_UPDATED' 
	where Email ='test_user@test_user.gmail' and Firstname ='Test' and Lastname = 'User';


----------------------------------------------------------------------------------------------------------
-- No one can modify credit_card_id
----------------------------------------------------------------------------------------------------------

--	first, we create a new credit card to user with User_ID = '0test_user'
--		(to neglect the involvements of any foreign key constraints)
--	and test on this one:

insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('0_New_Card', '1111111111111', 'New User', '11/4/2097', 123, 'New Address', '0_test_user');
select * from CreditCard;

-- attempting to modify this Credit_Card_ID, but it's failed (Error Message):
update CreditCard set Credit_Card_ID = '0_New_Card_UPDATED' 
	where Holder_Name ='New User' and Owner_ID ='0_test_user';


----------------------------------------------------------------------------------------------------------
-- No one can modify Order_ID
----------------------------------------------------------------------------------------------------------

--	first, we create a new order
--		(to neglect the involvements of any foreign key constraints)
--	and test on this one:

insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values
('0000001', '0_test_user', '1/1/2019', null, '0_New_Card', 'New Address', 'ready to ship');
select * from tblOrder;

-- attempting to modify this Product_ID, but it's failed (Error Message):
update tblOrder set Order_ID = '0000001_UPDATED' 
	where User_ID ='0_test_user' and Credit_Card_ID ='0_New_Card';
	
	
----------------------------------------------------------------------------------------------------------
-- No one can modify Product_ID
----------------------------------------------------------------------------------------------------------

--	first, we create a new product
--		(to neglect the involvements of any foreign key constraints)
--	and test on this one:

insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('00-00', 'New Product', 500, 'For Testing', '9.99', 95.35, '0.10');
select * from Product;

-- attempting to modify this Product_ID, but it's failed (Error Message):
update Product set Product_ID = '00-00_UPDATED' 
	where Name ='New Product' and Description ='For Testing';




------------END--------------

