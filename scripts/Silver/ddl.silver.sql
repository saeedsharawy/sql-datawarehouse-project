----Creating file Tables fro silver layer 
--before any table creation we will check the existance of it 
/*
script purpose :
Creating file Tables fro silver layer and before any table creation we will check the existance of it 
if exist table will be droped and then created 
--r run this script to redefine the ddl structure of  'bronze layer'

*/
if object_id ('silver.crm_cust_info','u') is not null
 drop table silver.crm_cust_info ;
create table silver.crm_cust_info (
cst_id int,
cst_key nvarchar(50),
cst_firstname nvarchar(50),
cst_lastname nvarchar(50),
cst_marital_status nvarchar(20),
cst_gndr nvarchar(20),
cst_create_date date,
dwh_creation_date datetime2 default getdate()
);

if object_id ('silver.crm_prd_info','u') is not null
 drop table silver.crm_prd_info ;

create table silver.crm_prd_info (
prd_id int,
prd_key nvarchar(50),
prd_nm nvarchar(50),
prd_cost nvarchar(50),
prd_line nvarchar(50),
prd_start_dt date,
prd_end_dt date,
dwh_creation_date datetime2 default getdate()
);

if object_id ('silver.crm_sales_details','u') is not null
 drop table silver.crm_sales_details ;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num  NVARCHAR(50),
    sls_prd_key  NVARCHAR(50),
    sls_cst_id   INT,
    sls_order_dt NVARCHAR(50),
    sls_ship_dt  NVARCHAR(50),
    sls_due_dt   NVARCHAR(50),
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT,
    dwh_creation_date datetime2 default getdate()
);
---creating  erp file tables

-- Customer
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid   NVARCHAR(50),
    bdate DATE,
    gen   NVARCHAR(50),
    dwh_creation_date datetime2 default getdate()
);


-- Location
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid   NVARCHAR(50),
    cntry NVARCHAR(50),
    dwh_creation_date datetime2 default getdate()
);


-- Product Category
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id          NVARCHAR(50),
    cat         NVARCHAR(50),
    subcat      NVARCHAR(50),
    maintenance NVARCHAR(50),
    dwh_creation_date datetime2 default getdate()
);
