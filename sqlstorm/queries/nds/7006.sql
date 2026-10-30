
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_sales
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 10
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDemographics AS (
    SELECT 
        ci.c_customer_sk,
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate
    FROM 
        TopItems ti
    JOIN 
        web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_sales) AS total_sales_value
FROM 
    SalesDemographics
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    total_sales_value DESC
LIMIT 5;
