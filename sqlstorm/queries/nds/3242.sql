
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
DemographicStats AS (
    SELECT
        cd.cd_gender,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_gender
),
BestSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_sold
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
    HAVING 
        SUM(COALESCE(ws.ws_quantity, 0)) > 100
)
SELECT 
    ds.cd_gender,
    ds.avg_purchase_estimate,
    ds.customer_count,
    bi.i_product_name,
    bi.total_sold
FROM 
    DemographicStats ds
FULL OUTER JOIN 
    BestSellingItems bi ON ds.customer_count > 50
ORDER BY 
    ds.cd_gender, bi.total_sold DESC
LIMIT 10;
