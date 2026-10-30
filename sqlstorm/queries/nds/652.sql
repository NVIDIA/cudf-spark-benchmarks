
WITH CustomerPromotion AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_net_profit ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_net_profit ELSE 0 END) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
PromotionStats AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        GREATEST(cp.total_web_sales, cp.total_catalog_sales, cp.total_store_sales) AS max_sales,
        (CASE 
            WHEN cp.total_web_sales > 0 AND cp.total_catalog_sales > 0 THEN 'Both Web and Catalog'
            WHEN cp.total_web_sales > 0 THEN 'Web Only'
            WHEN cp.total_catalog_sales > 0 THEN 'Catalog Only'
            ELSE 'No Sales' 
         END) AS sales_channel,
        RANK() OVER (ORDER BY GREATEST(cp.total_web_sales, cp.total_catalog_sales, cp.total_store_sales) DESC) AS sales_rank
    FROM CustomerPromotion cp
),
HighValueCustomers AS (
    SELECT 
        p.c_customer_sk,
        p.c_first_name,
        p.c_last_name,
        p.max_sales,
        p.sales_channel
    FROM PromotionStats p
    WHERE p.max_sales IS NOT NULL AND p.max_sales > 5000
)
SELECT 
    hv.c_customer_sk,
    hv.c_first_name || ' ' || hv.c_last_name AS full_name,
    hv.max_sales,
    hv.sales_channel
FROM HighValueCustomers hv
ORDER BY hv.max_sales DESC
LIMIT 10;
