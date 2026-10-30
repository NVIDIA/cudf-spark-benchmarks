
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
), 
SalesAnalysis AS (
    SELECT 
        c.*,
        CASE 
            WHEN total_store_sales > total_web_sales THEN 'Store'
            WHEN total_web_sales > total_store_sales THEN 'Web'
            ELSE 'Equal'
        END AS preferred_channel,
        DENSE_RANK() OVER (PARTITION BY 
            CASE 
                WHEN total_store_sales > total_web_sales THEN 'Store'
                WHEN total_web_sales > total_store_sales THEN 'Web'
                ELSE 'Equal'
            END 
            ORDER BY total_store_sales + total_web_sales DESC) AS sales_rank
    FROM CustomerSales c
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.preferred_channel,
    c.sales_rank,
    'Total sales from both channels: ' || CAST((c.total_store_sales + c.total_web_sales) AS STRING) AS total_sales_summary
FROM SalesAnalysis c
WHERE c.sales_rank = 1
    AND (c.total_store_sales IS NOT NULL OR c.total_web_sales IS NOT NULL)
    AND c.c_first_name IS NOT NULL
ORDER BY total_store_sales + total_web_sales DESC
LIMIT 10;
