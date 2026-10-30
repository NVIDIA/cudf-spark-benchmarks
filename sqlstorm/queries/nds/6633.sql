
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        rank <= 10
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_marital_status,
        cd_gender,
        hd_income_band_sk
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        household_demographics ON hd_demo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        tsi.ws_item_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.hd_income_band_sk,
        tsi.total_quantity,
        tsi.total_sales
    FROM 
        TopSellingItems tsi
    JOIN 
        web_sales ws ON tsi.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
)

SELECT 
    si.i_item_id,
    si.i_product_name,
    sds.c_first_name,
    sds.c_last_name,
    sds.cd_gender,
    sds.cd_marital_status,
    sds.total_quantity,
    sds.total_sales
FROM 
    SalesDetails sds
JOIN 
    item si ON sds.ws_item_sk = si.i_item_sk
ORDER BY 
    sds.total_sales DESC, sds.total_quantity DESC;
