
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate
    FROM customer_demographics cd
)
SELECT 
    cs.c_customer_sk, 
    cd.cd_gender,
    cd.cd_marital_status, 
    cd.cd_education_status, 
    cs.total_sales, 
    cs.store_transactions, 
    cs.catalog_transactions, 
    cs.web_transactions 
FROM customer_sales cs
JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE cs.total_sales > 1000
ORDER BY cs.total_sales DESC
LIMIT 50;
