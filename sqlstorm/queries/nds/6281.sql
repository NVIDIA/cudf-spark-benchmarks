
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id, 
        i.i_product_name, 
        rs.total_quantity, 
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesAnalysis AS (
    SELECT 
        ti.i_product_name, 
        SUM(td.customer_count) AS total_customers,
        SUM(ti.total_sales) AS total_sales
    FROM 
        TopItems ti
    JOIN 
        CustomerDemographics td ON ti.total_quantity > 50
    GROUP BY 
        ti.i_product_name
)
SELECT 
    sa.i_product_name, 
    sa.total_customers, 
    sa.total_sales,
    (sa.total_sales / NULLIF(sa.total_customers, 0)) AS sales_per_customer
FROM 
    SalesAnalysis sa
ORDER BY 
    sa.total_sales DESC;
