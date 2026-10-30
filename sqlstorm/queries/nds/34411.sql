
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales 
    GROUP BY 
        cs_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
aggregated_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(cs.total_orders, 0) AS total_orders,
        COALESCE(cs.total_spent, 0) AS total_spent
    FROM 
        sales_data sd
    LEFT JOIN 
        customer_info cs ON cs.c_customer_sk = sd.ws_item_sk
)
SELECT 
    a.ws_item_sk,
    a.total_quantity,
    a.total_sales,
    a.total_orders,
    a.total_spent,
    CASE 
        WHEN a.total_spent IS NULL THEN 'No purchases'
        ELSE CAST(a.total_spent AS STRING)
    END AS purchase_info
FROM 
    aggregated_sales a
WHERE 
    a.total_sales > 1000
ORDER BY 
    a.total_sales DESC
LIMIT 100;
