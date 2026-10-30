
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
shop_sales AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
),
combined_sales AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        CS.total_web_sales + COALESCE(ss.total_store_sales, 0) AS total_combined_sales,
        CASE 
            WHEN cs.total_web_sales IS NULL AND ss.total_store_sales IS NULL THEN 'No Sales'
            WHEN cs.total_web_sales IS NOT NULL AND ss.total_store_sales IS NULL THEN 'Web Only'
            WHEN cs.total_web_sales IS NULL AND ss.total_store_sales IS NOT NULL THEN 'Store Only'
            ELSE 'Both'
        END AS sale_type
    FROM 
        customer_sales cs
    FULL OUTER JOIN 
        shop_sales ss ON cs.c_customer_sk = ss.ss_customer_sk
),
sales_ranks AS (
    SELECT 
        c.*,
        DENSE_RANK() OVER (ORDER BY total_combined_sales DESC) AS sales_rank
    FROM 
        combined_sales c
    WHERE 
        total_combined_sales > (
            SELECT 
                AVG(total_combined_sales) 
            FROM 
                combined_sales
        )
)
SELECT 
    sr.c_customer_id,
    sr.sales_rank,
    (CASE 
        WHEN sr.sale_type = 'Both' THEN 'Top Customer'
        ELSE 'Regular Customer'
    END) AS customer_status
FROM 
    sales_ranks sr
WHERE 
    sr.sales_rank <= 10 OR sr.sale_type = 'No Sales'
ORDER BY 
    sr.sales_rank;
