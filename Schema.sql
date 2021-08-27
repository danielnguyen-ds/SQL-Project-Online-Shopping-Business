/*
- CSCI-6560 - FINAL PROJECT
- File name:	Schema.sql
- Written by:	Daniel Nguyen
- Date:			03/10/2019
- Description: this file contains SQL statements to to create all tables,
						 and/or views, and insert test data.
*/



/********************************
-- CREATING AND USING DATABASE
*********************************/
use Master
go

create database CSCI6560_Project;
go

use CSCI6560_Project
go



/*************************
	CREATING BASE TABLES
**************************/

----------------------------
-- table Customer
----------------------------
create table Customer (
	User_ID VARCHAR(50),
	Email VARCHAR(50),
	Password VARCHAR(200) NOT NULL,
	Firstname VARCHAR(50) NOT NULL,
	Lastname VARCHAR(50) NOT NULL,
	Address VARCHAR(50),
	Phone VARCHAR(50),
	Primary key (User_ID)
);
go


----------------------------
-- table CreditCard
----------------------------
create table CreditCard (
	Credit_Card_ID VARCHAR(50),
	Credit_Card_Number VARCHAR(200) NOT NULL,
	Holder_Name VARCHAR(50) NOT NULL,
	Expire_Date DATE,
	CVC_Code INT,
	Billing_Address VARCHAR(50),
	Owner_ID VARCHAR(50) NOT NULL,
	
	Primary key (Credit_Card_ID),
	Foreign key (Owner_ID) references Customer(User_ID), 
	
	CONSTRAINT pk__CreditCard__1 UNIQUE (Credit_Card_ID,Owner_ID)
);
go


----------------------------
-- table Product
----------------------------
create table Product (
	Product_ID VARCHAR(50) ,
	Name VARCHAR(50),
	Quantity INT NOT NULL,
	Description VARCHAR(50),
	Cost_Price VARCHAR(200),
	Sales_Price DECIMAL(10,2),
	Discount DECIMAL(4,2), 	
	Primary key (Product_ID),
	
	check (Discount > 0.0 and Discount < 1.0)
);
go


----------------------------
-- table tblOrder
----------------------------
create table tblOrder (
	Order_ID VARCHAR(50),
	User_ID VARCHAR(50) NOT NULL,
	Order_Date DATE,
	Total_Amount DECIMAL(10,2),
	Credit_Card_ID VARCHAR(50) not null,
	Shipping_address VARCHAR(50),
	Status VARCHAR(50), 
	
	Primary key (Order_ID),
	Foreign key (Credit_Card_ID,User_ID) references CreditCard(Credit_Card_ID,Owner_ID),

	-- constraint
	check (Status in ('placed','in preparation','ready to ship','shipped'))
);
go


----------------------------
-- table OrderItem
----------------------------
create table OrderItem (
	Order_ID VARCHAR(50) references tblOrder(Order_ID),
	Product_ID VARCHAR(50) references Product(Product_ID),
	PaidPrice DECIMAL(10,2),
	Quantity INT,
	
	Primary key (Order_ID,Product_ID),
	Foreign key (Order_ID) references tblOrder(Order_ID),
	Foreign key (Product_ID) references Product(Product_ID),

);
go



/********************************************
-- CREATING VIEWS 
*********************************************/

-----------------------------
-- View vCustomer
---------------------------
	-- can view own Customer information of current user;
	-- will be used by Role CustomerR
CREATE VIEW vCustomer
AS
SELECT User_ID, Email, Password, Firstname, Lastname, Address, Phone
FROM Customer
WHERE User_ID = current_user;
GO	


-----------------------------
-- View vCreditCard
---------------------------
	-- can view the last 4 digits and other infomation of credit cards of current user;
	-- will be used by Role CustomerR
CREATE VIEW vCreditCard 
AS
SELECT Credit_Card_ID
		, REPLICATE('*', DATALENGTH( dbo.func_DecryptingString(Credit_Card_Number) ) - 4) +
		                    Right( dbo.func_DecryptingString(Credit_Card_Number), 4) as Credit_Card_Number
		, Holder_Name, Expire_Date, CVC_Code, Billing_Address, Owner_ID
FROM CreditCard
WHERE Owner_ID = current_user;
GO


---------------------------
-- View vProduct
---------------------------
	-- can view information of all products excluding Cost_Price;
	-- will be used by Roles: CustomerR and CustomerServiceRepresentativeR
CREATE VIEW vProduct
AS
SELECT Product_ID, Name, Quantity, Description, Sales_Price, Discount
FROM Product;
GO	


-----------------------------
-- View vOrder
---------------------------
	-- can view Order excluding Total_Amount, Credit_Card_ID attributes;
	-- will be used by Role OrderProcessorR
CREATE VIEW vOrder
AS
SELECT Order_ID, User_ID, Order_Date, Shipping_address, Status
FROM tblOrder;
GO	


-----------------------------
-- View vOrderItem
---------------------------
	-- can view OrderItem excluding PaidPrice;	-- will be used by Role OrderProcessorR
CREATE VIEW vOrderItem
AS
SELECT Order_ID, Product_ID, Quantity
FROM OrderItem;
GO	



/****************************************
	INSERTING TEST DATA INTO BASE TABLES
****************************************/

----------------------------
-- table Customer:	
----------------------------
	--	NOTE: Password will be encrypted automatically.
insert into Customer (User_ID, Email, Password, Firstname, Lastname, Address, Phone) values 
('jnobes0', 'jnobes0@liveinternet.ru', 'f8kr1G2', 'Jacynth', 'Nobes', '77211 Muir Place', '467-492-2358');
insert into Customer (User_ID, Email, Password, Firstname, Lastname, Address, Phone) values
('kwarkup1', 'kwarkup1@indiegogo.com', 'XacgHJY72MG', 'Kirstyn', 'Warkup', '33417 South Circle', '704-895-6927');
insert into Customer (User_ID, Email, Password, Firstname, Lastname, Address, Phone) values
('ekiltie2', 'ekiltie2@geocities.jp', 'M2JkRGwHN7', 'Ephraim', 'Kiltie', '534 Dayton Street', '890-284-5254');
insert into Customer (User_ID, Email, Password, Firstname, Lastname, Address, Phone) values
('alebbern7', 'alebbern7@edublogs.org', 'RJ1v3vNwpe', 'Artus', 'Lebbern', '29232 Mariners Cove Alley', '694-216-2805');
GO

----------------------------
-- table Product
----------------------------
	--	NOTE: Cost_Price will be encrypted automatically.
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('AN-74', 'Cheese - Goat With Herbs', 493, 'Voonder', '47.79', 95.35, '0.10');
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('AT-63', 'Lemonade - Strawberry, 591 Ml', 531, 'Youbridge', '9.81', 42.73, '0.10');
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('AV-03', 'Soup - Campbells Beef Strogonoff', 784, 'Gigabox', '13.85', 18.87, '0.05');

insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('FI-72', 'Peas - Frozen', 567, 'Wikido', '41.4', 74.98, '0.20');
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('FJ-31', 'Wine - Duboeuf Beaujolais', 638, 'Gabtune', '19.99', 63.91, '0.05');

insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('MG-18', 'Chocolate - Dark Callets', 840, 'Trudeo', '22.44', 50.07, '0.20');
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('MW-01', 'Snails - Large Canned', 513, 'Oyope', '30.01', 65.86, '0.10');
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('MW-27', 'Bread - 10 Grain', 755, 'Realbridge', '46.22', 83.54, '0.20');

insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('UP-24', 'Wine - Red, Concha Y Toro', 743, 'Gabtune', '7.33', 79.76, '0.10');
insert into Product(Product_ID, Name, Quantity, Description, Cost_Price, Sales_Price, Discount) values
('WU-42', 'Pepper - Green, Chili', 589, 'Meedoo', '69.52', 130.01, '0.10');
GO


----------------------------
-- table CreditCard
----------------------------
	--	NOTE: Credit_Card_Number will be encrypted automatically.
insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('lmaclice0', '5100140101477018', 'Lowe MacLice', '11/4/1097', 781, '6506 Jenna Alley', 'alebbern7');
insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('kharvison1', '3562688088429689', 'Kim Harvison', '6/23/0877', 952, '196 Tennessee Way', 'alebbern7');

insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('fiskov2', '374622180112673', 'Francyne Iskov', '9/18/1477', 592, '3284 Arapahoe Plaza', 'ekiltie2');
insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('rdanshin3', '3576143074048485', 'Ricky Danshin', '10/10/1670', 131, '0629 Grover Hill', 'ekiltie2');

insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('ture4', '675946048754000904', 'Thorpe Ure', '7/14/1402', 786, '49550 Elka Trail', 'jnobes0');
insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('selderkin5', '201800462515271', 'Stormie Elderkin', '7/5/1113', 338, '5 Banding Lane', 'jnobes0');

insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('bconlaund6', '3540297989646867', 'Bobette Conlaund', '5/27/1530', 946, '926 Northport Trail', 'kwarkup1');
insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('gblumsom7', '30429624114513', 'Garrard Blumsom', '4/5/1452', 751, '3 5th Hill', 'kwarkup1');
insert into CreditCard (Credit_Card_ID,  Credit_Card_Number, Holder_Name,  Expire_Date, CVC_Code, Billing_Address, Owner_ID) values 
('lsomerscales8', '6759908231371075', 'Lorry Somerscales', '1/12/0777', 639, '0 Thierer Drive', 'kwarkup1');
GO

----------------------------
-- table tblOrder
----------------------------
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('2026260', 'alebbern7', '2/8/2019', null, 'kharvison1', '4 Dawn Parkway', 'ready to ship');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('0367501', 'alebbern7', '10/20/2018', null, 'kharvison1', '7068 Evergreen Avenue', 'shipped');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('0270223', 'alebbern7', '3/23/2018', null, 'lmaclice0', '638 Barnett Court', 'placed');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('4979937', 'alebbern7', '4/19/2018', null, 'lmaclice0', '986 Service Hill', 'placed');

insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('7929138', 'ekiltie2', '12/13/2018', null, 'fiskov2', '7680 Nancy Way', 'shipped');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('0788438', 'ekiltie2', '12/23/2018', null, 'fiskov2', '34 Sullivan Place', 'placed');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('5262330', 'ekiltie2', '11/19/2018', null, 'rdanshin3', '552 Erie Center', 'ready to ship');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('0314338', 'ekiltie2', '8/10/2018', null, 'rdanshin3', '0227 Lotheville Park', 'shipped');

insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('5404055', 'jnobes0', '1/19/2019', null, 'selderkin5', '489 Center Terrace', 'placed');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('9651880', 'jnobes0', '12/11/2018', null, 'selderkin5', '56523 Tennessee Parkway', 'ready to ship');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('7296835', 'jnobes0', '12/28/2018', null, 'ture4', '7 Manufacturers Junction', 'shipped');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('2938448', 'jnobes0', '12/25/2018', null, 'ture4', '8 Saint Paul Avenue', 'placed');

insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('9102700', 'kwarkup1', '7/13/2018', null, 'bconlaund6', '26 Schmedeman Park', 'shipped');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('0782901', 'kwarkup1', '9/21/2018', null, 'bconlaund6', '818 Knutson Drive', 'in preparation');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('2783860', 'kwarkup1', '10/18/2018', null, 'gblumsom7', '1 Monica Place', 'placed');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('5636311', 'kwarkup1', '8/10/2018', null, 'gblumsom7', '0689 Glacier Hill Center', 'ready to ship');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('9346846', 'kwarkup1', '2/23/2019', null, 'lsomerscales8', '64110 Burrows Point', 'in preparation');
insert into tblOrder(Order_ID, User_ID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status) values('6427939', 'kwarkup1', '1/2/2019', null, 'lsomerscales8', '93 Grim Circle', 'shipped');
GO

----------------------------
-- table OrderItem
----------------------------
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('2026260', 'AN-74', null, 9);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0367501', 'FJ-31', null, 6);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0367501', 'MG-18', null, 4);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0367501', 'MW-01', null, 8);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0367501', 'MW-27', null, 2);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0367501', 'UP-24', null, 4);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0367501', 'WU-42', null, 4);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0270223', 'AN-74', null, 9);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0270223', 'AT-63', null, 2);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0270223', 'AV-03', null, 3);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0270223', 'FI-72', null, 5);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0270223', 'FJ-31', null, 1);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0270223', 'MG-18', null, 9);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0270223', 'MW-01', null, 9);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('4979937', 'FI-72', null, 3);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('4979937', 'FJ-31', null, 3);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('4979937', 'MG-18', null, 3);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('4979937', 'MW-01', null, 3);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('4979937', 'MW-27', null, 3);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('4979937', 'UP-24', null, 3);

insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('7929138', 'AN-74', null, 6);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('7929138', 'AT-63', null, 6);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('7929138', 'AV-03', null, 6);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('7929138', 'FI-72', null, 6);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0788438', 'FI-72', null, 6);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0788438', 'FJ-31', null, 4);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0788438', 'MG-18', null, 8);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('5262330', 'MW-01', null, 9);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('5262330', 'MW-27', null, 2);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0314338', 'FI-72', null, 3);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0314338', 'FJ-31', null, 1);

insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('5404055', 'FI-72', null, 9);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('5404055', 'FJ-31', null, 6);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('5404055', 'MG-18', null, 4);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('9651880', 'MW-01', null, 8);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('9651880', 'MW-27', null, 2);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('7296835', 'AT-63', null, 3);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('7296835', 'AV-03', null, 1);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('2938448', 'AV-03', null, 6);

insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('9102700', 'AN-74', null, 1);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('9102700', 'AT-63', null, 4);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('9102700', 'AV-03', null, 4);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0782901', 'AV-03', null, 7);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0782901', 'FI-72', null, 7);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('0782901', 'FJ-31', null, 1);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('2783860', 'AV-03', null, 5);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('2783860', 'FI-72', null, 9);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('2783860', 'FJ-31', null, 9);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('2783860', 'MG-18 ', null, 8);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('2783860', 'MW-01', null, 3);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('2783860', 'MW-27', null, 5);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('5636311', 'MW-27', null, 8);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('5636311', 'UP-24', null, 4);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('5636311', 'WU-42', null, 1);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('9346846', 'WU-42', null, 9);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('6427939', 'FJ-31', null, 6);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('6427939', 'MG-18', null, 5);
insert into OrderItem (Order_ID, Product_ID, PaidPrice, Quantity) values ('6427939', 'MW-27', null, 3);
GO



------------END--------------

