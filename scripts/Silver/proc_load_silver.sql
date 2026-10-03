/*
# ===================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
=====================================================================

Script Purpose:
This stored procedure performs the ETL (Extract, Transform, Load) process to
populate the 'silver' schema tables from the 'bronze' schema.
Actions Performed:
- Truncates Silver tables.
- Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
None.
This stored procedure does not accept any parameters or return any values.

Usage Example:
EXEC Silver.load_silver;

*/

--exec silver.load_silver ;
create or alter procedure silver.load_silver as 
begin
    declare @start_time datetime,@end_time datetime , @batch_start_time datetime , @batch_end_time datetime 
	set @batch_start_time =GETDATE();
	begin try
        print ('==========================================================');
	    print ('Loading Silver Layer');
	    print ('==========================================================');
        --====================================================================

	    print ('==========================================================');
	    print (' Insert CRM Source Table ');
	    print ('==========================================================');
        --=================================
        -- crm cust info 
        --=================================
        set @start_time =GETDATE();
        print '>> Truncating The Table : Silver.crm_cust_info ';
        truncate table Silver.crm_cust_info ;
        print '>> Inserting Data Into  : Silver.crm_cust_info ';
        insert into Silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
        )

        select 
        cst_id,
        cst_key,
        trim(cst_firstname) as cst_firstname ,
        trim(cst_lastname)  as cst_lastname,

        case when upper (trim(cst_marital_status)) = 'M' then 'Married'
             when upper (trim(cst_marital_status)) = 'S' then 'Single'
             else 'UnKnown'
        end cst_marital_status, --Normalize marital status to readable format 
        case when upper (trim(cst_gndr ))= 'M' then 'Male'
             when upper (trim(cst_gndr)) = 'F' then 'Female'
             else 'UnKnown'
        end cst_gndr ,--Normalize gender to readable format 

        cst_create_date
        from
        (
        -- this a subquery used to only get the unique dat from the table and avoid repeated data
        select 
        *,
        ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_order
        from bronze.crm_cust_info
        where cst_id is not null

        ) t
        where flag_order = 1
        set @end_time =getdate();
	    print 'Load Duration :' + cast(datediff(second,@start_time,@end_time) as nvarchar) +'seconds';
	    print'-----------------------------------------------';
        --===================================================
        -- crm PRD info 
        --===================================================
        set @start_time =GETDATE();
        print '>> Truncating The Table : silver.crm_prd_info ';
        Truncate Table silver.crm_prd_info ;
        print '>> Inserting Data Into  : silver.crm_prd_info ';
        --inserting the date into the table 
        insert into silver.crm_prd_info (
        prd_id,
        prd_cat ,
        prd_key ,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_date,
        prd_end_date  
        )
        select 
        prd_id,
        replace(substring(prd_key,1,5) ,'-','_') as prd_cat,
        substring (prd_key,7, len(prd_key)) as prd_key,
        prd_nm,
        ISNULL (prd_cost,0) as prd_cost,
        case
          when upper(trim(prd_line)) = 'M' then 'Mountain'
          when upper(trim(prd_line)) = 'R' then 'Road'
          when upper(trim(prd_line)) = 'S' then 'Other Sales'
          when upper(trim(prd_line)) = 'T' then 'Touring'
        else 'n/a'
        end prd_line,
        cast(prd_start_dt as date ) as prd_start_date ,
        DATEADD(
            DAY,
            -1,
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key 
                ORDER BY prd_start_dt
            )
        ) AS prd_end_date
        from bronze.crm_prd_info 
        set @end_time =getdate();
	    print 'Load Duration :' + cast(datediff(second,@start_time,@end_time) as nvarchar) +'seconds';
	    print'-----------------------------------------------';
        --======================================-
        -- Sales_details
        --======================================-
        set @start_time =GETDATE();
        print '>> Truncating The Table : silver.crm_sales_details ';
        Truncate Table silver.crm_sales_details;
        print '>> Inserting Data Into  : silver.crm_sales_details ';
        insert into silver.crm_sales_details (
        sls_cst_id,
        sls_ord_num,
        sls_prd_key,
        sls_order_date,
        sls_ship_date,
        sls_due_date,
        sls_sales,
        sls_quantity,
        sls_price
        )
        select 
        sls_cst_id,
        sls_ord_num,
        sls_prd_key,
        case 
            when sls_order_dt  < 0   or sls_order_dt = 0  or len (sls_order_dt) != 8 then null 
            else cast( cast(sls_order_dt as varchar ) as date )
        end sls_order_date,
        case 
            when sls_ship_dt  < 0   or sls_ship_dt = 0  or len (sls_ship_dt) != 8 then null 
            else cast( cast(sls_ship_dt as varchar ) as date )
        end sls_ship_date,
        case 
            when sls_due_dt  < 0   or sls_due_dt = 0  or len (sls_due_dt) != 8 then null 
            else cast( cast(sls_due_dt as varchar ) as date )
        end sls_due_date,
        case 
            when sls_sales is null or sls_sales < 0 or sls_sales != sls_quantity * abs(sls_price) 
            then sls_quantity * abs(sls_price)
            else sls_sales
        end sls_sales,
        sls_quantity,
        case 
            when sls_price < 0 or sls_price is null or sls_price =0
            then sls_sales / nullif (sls_quantity,0) --we cant divide on 0  so it is to be save to divide by null rather than 0
            else sls_price
        end sls_price
        from bronze.crm_sales_details;
        set @end_time =getdate();
	    print 'Load Duration :' + cast(datediff(second,@start_time,@end_time) as nvarchar) +'seconds';
	    print'-----------------------------------------------';
        print ('==========================================================');
	    print (' Insert ERP Source Table ');
	    print ('==========================================================');
        ---====================================--
        --erp cust az12
        --=====================================--
        set @start_time =GETDATE();
        print '>> Truncating The Table : silver.erp_cust_az12  ';
        Truncate Table silver.erp_cust_az12 ;
        print '>> Inserting Data Into  : silver.erp_cust_az12  ';
        insert into silver.erp_cust_az12 (cid,bdate,gen)
        select 
        case when cid like 'NAS%' then substring (cid,4,len(cid))
             else cid
        end cid,
        case when bdate > getdate() then null 
             else bdate
        end  bdate,
        case when  upper (trim (gen)) in ('F', 'FEMALE') then 'Female'
             when  upper (trim (gen)) in ('M', 'MALE' )  then 'Male'
             else 'n/a'
        end gen
        from bronze.erp_cust_az12
        set @end_time =getdate();
	    print 'Load Duration :' + cast(datediff(second,@start_time,@end_time) as nvarchar) +'seconds';
	    print'-----------------------------------------------';
        --====================================
        --erp loc
        --====================================
        set @start_time =GETDATE();
        print '>> Truncating The Table : silver.erp_loc_a101  ';
        Truncate Table silver.erp_loc_a101 ;
        print '>> Inserting Data Into  : silver.erp_loc_a101  ';
        insert into silver.erp_loc_a101 (cid,cntry)
        select  
        replace (cid ,'-','') cid ,
        case
	        when trim(cntry) = 'DE' then 'Germany '
	        when trim(cntry) in ('US','USA','Unitedd States') then 'United States'
	        when trim(cntry) = '' or cntry is null  then 'n/a'
	        else trim(cntry)
        end cntry
        from bronze.erp_loc_a101
        set @end_time =getdate();
	    print 'Load Duration :' + cast(datediff(second,@start_time,@end_time) as nvarchar) +'seconds';
	    print'-----------------------------------------------';
        ---======================================
        --erp cat g1v2
        --=======================================
        set @start_time =GETDATE();
        print '>> Truncating The Table : silver.erp_px_cat_g1v2  ';
        Truncate Table silver.erp_px_cat_g1v2 ;
        print '>> Inserting Data Into  : silver.erp_px_cat_g1v2  ';
        insert into  silver.erp_px_cat_g1v2 (id ,cat , subcat ,maintenance)
        select
        trim(id) id,
        trim(cat) cat  ,
        trim(subcat) subcat,
        trim(maintenance) maintenance
        from bronze.erp_px_cat_g1v2;
        set @end_time =getdate();
	    print 'Load Duration :' + cast(datediff(second,@start_time,@end_time) as nvarchar) +'seconds';
	    print'-----------------------------------------------';
    end try 
    begin catch
	print '============================================';
	print 'Error Acuured During Loadinf The Data';
	print 'Error Message' + error_message();
	print 'Error Number'  + cast (error_number() as nvarchar);
	print '============================================';
	end catch
		set @batch_end_time =getdate();
		print 'Whole Batch Load Duration :' + cast(datediff(second,@start_time,@end_time) as nvarchar) +'seconds';
		print'-----------------------------------------------';
end 
