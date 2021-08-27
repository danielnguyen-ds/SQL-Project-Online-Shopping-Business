

================== ALL SETTINGS ================================

1- Create/Set up:
    + database [CSCI6560_Project]
    + base tables [Customer, CreditCard, Product, tblOrder, OrderItem]
    
--> by running: line 15 - line 120, file: Schema.sql    



2- Create/Set up Auditing
    +  Auditing Data Modification on Product table:
        - Product_Audit table that contains all changes made to Product table
        - DML trigger trig_Product_Audit
        
    + SQL Server Audit:
        - Server audit specification SAS_TotalAudit: that audits successful/failed login and logout events
        - Database audit specification DAS_TotalAudit: that tracks any permission changes by GRANT/REVOKE/DENY statements

        *** NOTE: Please assign an appropriate FilePath for the audit file (.sqlaudit)
        
--> by running: line 15 - line 228, file: Auditing.sql



3- Create/Set up/Start Encryptions
    + Database master key, asymmetric key, symmetric key.
    + Creating supporting procedure and function: sp_EncryptingString and func_DecryptingString
    + Encrypting Customer.Password
    + Encrypting CreditCard.Credit_Card_Nuber
    + Encrypting Product.Cost_Price (this process includes a constraint for Costs of Product table 
            to Ensure that Cost Price is smaller or equal to the Sales Price after discounted)
    
--> by running: line 15 - line 168, file: Encrypt.sql



4- Create/Set up Views:
    + View vCustomer: 
	    -- can view own Customer information of current user;
	    -- will be used by Role CustomerR
    + View vCreditCard:
 	 	-- can view the last 4 digits of credit cards of current user;
	    -- will be used by Role CustomerR  
	+ View vProduct:
		-- can view information of all products excluding Cost_Price;
	    -- will be used by Roles: CustomerR and CustomerServiceRepresentativeR
	+ View vOrder:
		-- can view Order excluding Total_Amount, Credit_Card_ID attributes;
	    -- will be used by Role OrderProcessorR
	+ View vOrderItem:
		-- can view OrderItem excluding PaidPrice;	
		-- will be used by Role OrderProcessorR
	    
--> by running: line 132 - line 190, file: Schema.sql  



5-  Create/Set up PROCEDURES, used by particular ROLES:
    + procedure sp_delete_from_OrderItem:
        -- delete an order item from a placed order only if the order status is “in preparation”;
	    -- will be used by Role CustomerServiceRepresentativeR
    + procedure sp_update_from_OrderItem:
    	-- update the quantity of an order item from a placed order only if the order status is “in preparation”;
	    -- will be used by Role CustomerServiceRepresentativeR
    + procedure sp_insert_from_OrderItem: 
    	-- update the quantity of an order item from a placed order only if the order status is “in preparation”;
	    -- will be used by Role CustomerServiceRepresentativeR
    + procedure sp_update_from_Product:
    	-- update Product table but cannot modify Cost_Price, Sales_Price, and Discount attributes;
	    -- will be used by Role SaleR
    + procedure sp_delete_from_Product:
    	-- remove a product from database if its quantity is 0 ;
	    -- will be used by Role Role SaleManagerR
    + procedure sp_update_from_tblOrder:
        -- only modify Status attribute of Order table;
	    -- will be used by Role OrderProcessorR
	+ procedure sp_remove_order_from_tblOrder:
	    -- remove any orders that have no order items
	    -- will be used in the Trigger trig_OrderItem_delete
	    
 - Create/Set up Triggers on Base Tables   
    + Trigger trig_tblOrder:
    	-- print a formatted message when the order status is changed to 'shipped'
	    -- deduct OrderItem.Quantity from Product.Quantity for each order item when an order is placed
    + Trigger trig_OrderItem: 
        -- ensure OrderItem.PaidPrice and Order.Total_Amount should always be calculated automatically
    + Trigger trig_OrderItem_delete:
    	-- add OrderItem.Quantity back to Product.Quantity when an order item is removed;
        -- AND remove any Orders, if they exist, which have NO order items
    + Trigger trig_unchangeUserID:
        -- ensure no one can modify User_ID
    + Trigger trig_unchangeCreditCardID
    	-- ensure no one can modify CreditCardID
    + Trigger trig_unchangeOrderID
    	-- ensure no one can modify OrderID
    + Trigger trig_unchangeProductID
    	-- ensure no one can modify ProductID
    	
 - Create/Set up Triggers on Views
    + Trigger trig_updateViewCustomer
    	-- ensure the current user can update his own information
    + Trigger trig_deleteViewCreditCard
        -- ensure the current user can remove his own credit card
    + Trigger trig_insertViewCreditCard
        -- ensure the current user can insert his own credit card
    + Trigger trig_updateViewCreditCard
    	-- ensure the current user can only modify Holder_Name and Billing_Address of existing credit card
       
--> by running: line 15 - line 464, file: Objects.sql --END
 

 
6- Create/Set up logins/users/Roles and statements to grant/deny/revoke permissions
    
--> by running: line 15 - line 180, file: Permission.sql --END
 
  
    
7-  Insert test data into base tables:
    + Note that Customer.Password, CreditCard.Credit_card_number, and Product.Cost_Price will be encrypted automatically
   
--> by running: line 200 - line 360, file: Schema.sql --END


================== TESTINGS ================================


8- Test EACH cases to demonstrate the satisfaction of all constraints and requirement as well as permission requirements:

--> by running: line 15 - line 590, file: Testing.sql --END



9- Retrieve Product table with clear text on Cost_Price

--> by running: line 178 - line 179, file: Encrypt.sql --END



10- Track all changes and audit sessions:

--> by running: line 244 - line 298, file: Auditing.sql --END

    ** NOTE: If the user 'csr_userL', for example, attempts to login to the Server,
                 using Authentication as SQL Server authentication, and a WRONG Password (NOT '@123abcABC123'),
            then he will be failed to connect to the Server and those Failed login actions (with action_id = 'LGIF')
            should be recorded in the Audit file TotalAudit*.sqlaudit












    
