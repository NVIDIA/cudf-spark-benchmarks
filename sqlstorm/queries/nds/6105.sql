
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy BETWEEN 1 AND 3)
    GROUP BY 
        c.c_customer_sk
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy BETWEEN 1 AND 3)
    GROUP BY 
        c.c_customer_sk
),
CombinedSales AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        (COALESCE(cs.web_order_count, 0) + COALESCE(ss.store_order_count, 0)) AS total_order_count
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
)
SELECT 
    c.c_customer_id,
    cs.total_web_sales,
    cs.total_store_sales,
    cs.total_sales,
    cs.total_order_count
FROM 
    CombinedSales cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    cs.total_sales > 0
ORDER BY 
    total_sales DESC
LIMIT 10;
