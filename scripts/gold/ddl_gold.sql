/*
===================================================================
DDL Script: Create Gold Views
===================================================================

Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===================================================================
*/
--=================================================
--Create Customer View
--=================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO
create view gold.dim_customers as
select 
row_number() over (order by ci.cst_id ) as customer_key,
ci.cst_id as customer_id,
ci.cst_key as customer_code,
ci.cst_firstname as firstname,
ci.cst_lastname as lastname,
case when ci.cst_gndr != 'UnKnown' then ci.cst_gndr
     else coalesce(ca.gen,'n/a')
end gender,
ci.cst_marital_status as marital_status,
cl.cntry as country ,
ca.bdate as birth_date,
ci.cst_create_date as create_date
from silver.crm_cust_info ci 
left join silver.erp_cust_az12 ca
on ci.cst_key = ca.cid
left join silver.erp_loc_a101 cl
on ci.cst_key = cl.cid
go
--=================================================
--Create product View
--=================================================
IF OBJECT_ID('gold.dim_product', 'V') IS NOT NULL
    DROP VIEW  gold.dim_product;
GO
create view gold.dim_product as
select 
row_number() over (order by pn.prd_start_date ,pn.prd_key) as product_key,
pn.prd_id as product_id,
pn.prd_key as product_code,
pn.prd_nm as product_name,
pn.prd_cat as category_id,
pc.cat as category ,
pc.subcat as sub_category ,
pc.maintenance as maintenance ,
pn.prd_cost as cost ,
pn.prd_line as product_Line,
pn.prd_start_date as start_date
from silver.crm_prd_info pn
left  join silver.erp_px_cat_g1v2 pc
on pn.prd_cat = pc.id
where pn.prd_end_date is null
go
--=================================================
--Create Sales View
--=================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
create view gold.fact_sales as
select  
sd.sls_ord_num as order_number,
cu.customer_key,
pr.product_key,
sd.sls_sales as sales,
sd.sls_quantity as quantity,
sd.sls_price as price,
sd.sls_order_date as order_date,
sd.sls_ship_date as ship_date,
sd.sls_due_date as due_date
from silver.crm_sales_details sd
left join gold.dim_customers cu
on sd.sls_cst_id = cu.customer_id
left join gold.dim_product pr
on sd.sls_prd_key = pr.product_code
go
