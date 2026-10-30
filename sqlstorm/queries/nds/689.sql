
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_ext_sales_price), 0) DESC) AS rank_web_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
HighSpenders AS (
    SELECT 
        c.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales
    FROM 
        CustomerSales cs
    JOIN customer c ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_web_sales > (
            SELECT 
                AVG(total_web_sales) 
            FROM 
                CustomerSales
        ) 
        OR cs.total_catalog_sales > (
            SELECT 
                AVG(total_catalog_sales) 
            FROM 
                CustomerSales
        )
)
SELECT 
    cs.c_customer_id,
    CASE 
        WHEN cs.total_web_sales > 0 THEN 'Web'
        WHEN cs.total_catalog_sales > 0 THEN 'Catalog'
        ELSE 'Store'
    END AS primary_channel,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    COALESCE(NULLIF(cs.total_web_sales, 0), NULLIF(cs.total_catalog_sales, 0), cs.total_store_sales) AS primary_revenue,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(cs.total_web_sales) OVER () AS max_web_sales,
    MIN(cs.total_catalog_sales) OVER () AS min_catalog_sales
FROM 
    CustomerSales cs
JOIN HighSpenders hs ON cs.c_customer_id = hs.c_customer_id
LEFT JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    cs.c_customer_id, cs.total_web_sales, cs.total_catalog_sales, cs.total_store_sales
HAVING 
    COALESCE(NULLIF(cs.total_web_sales, 0), NULLIF(cs.total_catalog_sales, 0), cs.total_store_sales) IS NOT NULL
ORDER BY 
    cs.total_web_sales DESC, cs.total_catalog_sales DESC;
