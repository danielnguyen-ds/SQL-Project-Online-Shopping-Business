/*
- CSCI-6560 - FINAL PROJECT
- File name:	Object.sql
- Written by:	Daniel Nguyen
- Date:			03/10/2019
- Description: this file contains SQL stored procedures, functions, triggers,
					 and other statements to implement all constraints.
*/



/********************************
	USING DATABASE
*********************************/
use CSCI6560_Project
go




/******************************************
	PROCEDURES, used by particular ROLES
*******************************************/

------------------------------------------
--	procedure sp_delete_from_OrderItem 
------------------------------------------	
	-- delete an order item from a placed order only if the order status is “in preparation”;
	-- will be used by Role CustomerServiceRepresentativeR
CREATE PROCEDURE sp_delete_from_OrderItem 
	@orderID varchar(50), 
	@productID varchar(50)
AS
BEGIN
declare @status varchar(50);
select @status = Status from tblOrder where Order_ID = @orderID;

if (@status = 'in preparation')
	delete from OrderItem where Order_ID = @orderID and Product_ID = @productID;
else 
	print 'CANNOT remove this order item from a placed order because its order status is ''' + @status +'''.'
END
GO


------------------------------------------
--	procedure sp_update_from_OrderItem 
------------------------------------------	
	-- update the quantity of an order item from a placed order only if the order status is “in preparation”;
	-- will be used by Role CustomerServiceRepresentativeR
CREATE PROCEDURE sp_update_from_OrderItem 
	@orderID varchar(50), 
	@productID varchar(50),
	@quant int
AS
BEGIN
declare @status varchar(50);
select @status = Status from tblOrder where Order_ID = @orderID;

if (@status = 'in preparation')
	update OrderItem set Quantity = @quant 
		where Order_ID = @orderID and Product_ID = @productID;
else 
	print 'CANNOT update this order item from a placed order because its order status is ''' + @status +'''.'
END
GO


------------------------------------------
--	procedure sp_insert_from_OrderItem 
------------------------------------------	
	-- update the quantity of an order item from a placed order only if the order status is “in preparation”;
	-- will be used by Role CustomerServiceRepresentativeR
CREATE PROCEDURE sp_insert_from_OrderItem 
	@orderID varchar(50), 
	@productID varchar(50),
	@quant int
AS
BEGIN
declare @status varchar(50);
select @status = Status from tblOrder where Order_ID = @orderID;

if (@status = 'in preparation')
	insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) 
		values (@orderID, @productID, null, @quant);
else 
	print 'CANNOT insert this order item to a placed order because its order status is ''' + @status +'''.'
END
GO


------------------------------------------
--	procedure sp_update_from_Product
------------------------------------------	
	-- update Product table but cannot modify Cost_Price, Sales_Price, and Discount attributes;
	-- will be used by Role SaleR
CREATE PROCEDURE sp_update_from_Product 
	@productID varchar(50),
	@name varchar(50),
	@quant int,
	@desc varchar(50)
AS
BEGIN
update Product set 
		Name = @name, 
		Quantity = @quant,
		Description = @desc
		where Product_ID = @productID;
END
GO


------------------------------------------
--	procedure sp_delete_from_Product
------------------------------------------	
	-- remove a product from database if its quantity is 0 ;
	-- will be used by Role SaleManagerR
CREATE PROCEDURE sp_delete_from_Product
	@productID varchar(50)
AS
BEGIN
declare @quant int;
select @quant = Quantity from Product where Product_ID = @productID;

if (@quant = 0)
	delete from Product where Product_ID = @productID;
else 
	print 'CANNOT remove the product from database because its quantity is ' + CAST(@quant AS VARCHAR) + '.'
END
GO


------------------------------------------
--	procedure sp_update_from_tblOrder
------------------------------------------	
	-- only modify Status attribute of Order table;
	-- will be used by Role OrderProcessorR
CREATE PROCEDURE sp_update_from_tblOrder
	@orderID varchar(50),
	@status varchar(50)
AS
update tblOrder set Status = @status 
		where Order_ID = @orderID;
GO


--------------------------------------------
--	procedure sp_remove_order_from_tblOrder
--------------------------------------------
	-- remove any orders that have no order items 
	-- will be used in Trigger trig_OrderItem_delete
CREATE PROCEDURE sp_remove_order_from_tblOrder
AS
delete from tblOrder 
where Order_ID in
	(	select Order_ID from tblOrder
		except
		select Order_ID from OrderItem
	)
GO





/****************************
	TRIGGERS ON BASE TABLES
*****************************/

----------------------------------
-- Trigger trig_tblOrder
----------------------------------
	-- print a formatted message when the order status is changed to 'shipped'
	-- deduct OrderItem.Quantity from Product.Quantity for each order item 
	--			when an order is placed
create trigger trig_tblOrder
on tblOrder
for update, insert
as
begin
	declare	 @orderID varchar(50);
	declare	 @ccID varchar(50);
	declare @status varchar(50);
	
	select @orderID = Order_ID from Inserted;
	select @ccID = Credit_Card_ID from Inserted;
	select @status = Status from Inserted;
	
	-- prints a formatted message when the order status is changed to 'shipped'
	if ( UPDATE(Status) and @status = 'shipped' )
	begin
		declare @ta DECIMAL(10,2);
		declare	 @last4dig varchar(4);
		
		-- get Total_Amount
		select @ta = Total_Amount from tblOrder where Order_ID = @orderID;
		
		-- get last 4 digits of CreditCardNumber
		select @last4dig = right(dbo.func_DecryptingString(Credit_Card_Number),4) 
			from CreditCard where Credit_Card_ID = @ccID;
			
		-- print Message out
		print 'Credit Card ending with ' +  @last4dig +
			 ' is charged $' + CAST(@ta AS VARCHAR) +
			 ' for the order with order id ' + @orderID + '.' ;
	end
	
	-- When an order is placed, deduct OrderItem.Quantity from Product.Quantity for each order item.
	if ( UPDATE(Status) and @status = 'placed' )
	begin
		-- temporary table of the Products with updated Quantities
		DECLARE @myTableVariable TABLE (Product_ID varchar(50), Quantity int)
		insert into @myTableVariable
		select P.Product_ID, P.Quantity - O.Quantity
		from OrderItem O
		inner join Product P on O.Product_ID = P.Product_ID
		where Order_ID = @orderID;
		
		-- Raise an error if the updated quantity is too large
		if exists (select Product_ID from @myTableVariable where Quantity < 0)
		begin
      		RAISERROR('Error, this quantity value is TOO LARGE (larger than the quantity value of this product). ',10,1);
      		ROLLBACK TRANSACTION;
      		RETURN;
		end		

		-- updating
		update Product set Quantity = M.Quantity 
		from Product P
		inner join @myTableVariable M on P.Product_ID = M.Product_ID;
	end
	
end
go


----------------------------------
-- Trigger trig_OrderItem
----------------------------------
	-- ensure OrderItem.PaidPrice and Order.Total_Amount should always be calculated automatically.
create trigger trig_OrderItem
on OrderItem
after insert, update
as
begin
	declare	 @orderID varchar(50);
	declare	 @productID varchar(50);
	declare @pp DECIMAL(10,2);
	declare @ta DECIMAL(10,2)
		
	select @orderID = Order_ID from Inserted;
	select @productID = I.Product_ID from Inserted I;
	
	-- update OrderItem.PaidPrice
	select @pp = (1.0-Discount)*Sales_Price from Product where Product_ID = @productID;
	update OrderItem set PaidPrice = @pp where Product_ID = @productID and Order_ID = @orderID;

	-- update tblOrder.Total_Amount
	select @ta = sum(PaidPrice*Quantity)
						from OrderItem where Order_ID = @orderID
						group by Order_ID ;
	update tblOrder set Total_Amount = @ta where Order_ID = @orderID;

			
end
go


----------------------------------
-- Trigger trig_OrderItem_delete
----------------------------------
	-- add OrderItem.Quantity back to Product.Quantity when an order item is removed;
	-- AND remove any Orders, if they exist, which have NO order items
create trigger trig_OrderItem_delete
on OrderItem
after delete
as
begin
	declare @quant int;
	declare	 @productID varchar(50);
	select @quant = Quantity from Deleted;	
	select @productID = Product_ID from Deleted;
	
	-- add OrderItem.Quantity back to Product.Quantity
	update Product set Quantity = Quantity + @quant where Product_ID = @productID;

	-- remove any orders, if they exist, which have no order items 
	exec dbo.sp_remove_order_from_tblOrder;

end
go

 
----------------------------------
-- Trigger trig_unchangeUserID
----------------------------------
	-- ensure no one can modify User id
create trigger trig_unchangeUserID
on Customer
for update
as
begin
	if update(User_ID) 
		BEGIN
       RAISERROR('Error, you cannot change User ID', 16, 1)
       ROLLBACK
       RETURN
    	END
end
go


---------------------------------------
-- Trigger trig_unchangeCreditCardID
---------------------------------------
	-- ensure no one can modify CreditCardID
create trigger trig_unchangeCreditCardID
on CreditCard
for update
as
begin
	if update(Credit_Card_ID) 
		BEGIN
       RAISERROR('Error, you cannot change Credit Card ID', 16, 1)
       ROLLBACK
       RETURN
    END
end
go


----------------------------------
-- Trigger trig_unchangeOrderID
----------------------------------
	-- ensure no one can modify OrderID
create trigger trig_unchangeOrderID
on tblOrder
for update
as
begin
	if update(Order_ID) 
		BEGIN
       RAISERROR('Error, you cannot change Order ID', 16, 1)
       ROLLBACK
       RETURN
    END
end
go


----------------------------------
-- Trigger trig_unchangeProductID
----------------------------------
	-- ensure no one can modify ProductID
create trigger trig_unchangeProductID
on Product
for update
as
begin
	if update(Product_ID) 
		BEGIN
       RAISERROR('Error, you cannot change Product ID', 16, 1)
       ROLLBACK
       RETURN
    END
end
go



/*************************
	TRIGGERS ON VIEWS
**************************/

------------------------------------
-- Trigger trig_updateViewCustomer
------------------------------------
	-- ensure the current user can update his own information
create trigger trig_updateViewCustomer
on vCustomer
instead of update
as
begin
	SET NOCOUNT ON;
	declare @user VARCHAR(50) = current_user;
	
	-- cannot update (User_ID)
	if update(User_ID) 
		BEGIN
       RAISERROR('Error, you cannot change User ID', 16, 1)
       ROLLBACK
       RETURN
    	END	
    	
	update C
	set	C.Email = I.Email, 
		C.Firstname = I.Firstname, 
		C.Lastname = I.Lastname,
		C.Password = I.Password,
		C.Address = I.Address, 
		C.Phone = I.Phone
	from Customer C inner join inserted I on C.User_ID = I.User_ID
	where C.User_ID = @user;	
end 
go


--------------------------------------
-- Trigger trig_deleteViewCreditCard
--------------------------------------
	-- ensure the current user can remove his own credit card
create trigger trig_deleteViewCreditCard
on vCreditCard
instead of delete
as
begin
	SET NOCOUNT ON;
	declare @user VARCHAR(50) = current_user;
	
	delete from C 
	from CreditCard C inner join deleted D on C.Credit_Card_ID = D.Credit_Card_ID
	where C.Owner_ID = @user;	
end 
go


--------------------------------------
-- Trigger trig_insertViewCreditCard
--------------------------------------
	-- ensure the current user can insert his own credit card
create trigger trig_insertViewCreditCard
on vCreditCard
instead of insert
as
begin
	SET NOCOUNT ON;
	declare @user VARCHAR(50) = current_user;
		
	Insert into CreditCard (Credit_Card_ID, Credit_Card_Number, Holder_Name, Expire_Date, CVC_Code, Billing_Address, Owner_ID) 
   		             select Credit_Card_ID, Credit_Card_Number, Holder_Name, Expire_Date, CVC_Code, Billing_Address, @user from inserted;
end 
go


--------------------------------------
-- Trigger trig_updateViewCreditCard
--------------------------------------
	-- ensure the current user can only modify Holder_Name and Billing_Address of existing credit card
create trigger trig_updateViewCreditCard
on vCreditCard
instead of update
as
begin
	SET NOCOUNT ON;
	declare @user VARCHAR(50) = current_user;
	
	update C
	set	C.Holder_Name = I.Holder_Name, 
		C.Billing_Address = I.Billing_Address
	from CreditCard C inner join inserted I on C.Credit_Card_ID = I.Credit_Card_ID
	where C.Owner_ID = @user;	
end 
go







------------END--------------

