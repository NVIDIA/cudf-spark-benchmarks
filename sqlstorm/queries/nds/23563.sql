
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_sales_price), 0) DESC) AS rnk
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        CASE
            WHEN total_web_sales > 1000 THEN 'High Web Value'
            WHEN total_catalog_sales > 1000 THEN 'High Catalog Value'
            WHEN total_store_sales > 1000 THEN 'High Store Value'
            ELSE 'Regular Value'
        END AS customer_value_category
    FROM CustomerSales cs
    WHERE cs.rnk = 1
),
SalesDetail AS (
    SELECT 
        cs.c_customer_sk,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(cs2.cs_quantity) AS total_catalog_quantity,
        SUM(ss.ss_quantity) AS total_store_quantity,
        CASE 
            WHEN SUM(ws.ws_quantity) IS NULL THEN 'Web Not Purchased'
            ELSE 'Web Purchased'
        END AS purchase_status
    FROM CustomerSales cs
    LEFT JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs2 ON cs.c_customer_sk = cs2.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON cs.c_customer_sk = ss.ss_customer_sk
    GROUP BY cs.c_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(hvc.customer_value_category, 'Uncategorized') AS value_category,
    COALESCE(sd.total_web_quantity, 0) AS web_quantity,
    COALESCE(sd.total_catalog_quantity, 0) AS catalog_quantity,
    COALESCE(sd.total_store_quantity, 0) AS store_quantity,
    sd.purchase_status
FROM customer c
LEFT JOIN HighValueCustomers hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN SalesDetail sd ON c.c_customer_sk = sd.c_customer_sk
WHERE 
    (hvc.customer_value_category IS NOT NULL OR sd.purchase_status = 'Web Not Purchased')
    AND (hvc.customer_value_category IS NULL OR sd.total_web_quantity > 0)
ORDER BY c.c_customer_id;
