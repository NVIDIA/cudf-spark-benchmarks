
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
store_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        ss.total_store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(cs.total_web_sales, 0) > COALESCE(ss.total_store_sales, 0) THEN 'Web'
            WHEN COALESCE(cs.total_web_sales, 0) < COALESCE(ss.total_store_sales, 0) THEN 'Store'
            ELSE 'Equal'
        END AS preferred_channel
    FROM 
        customer_sales cs
    FULL OUTER JOIN 
        store_sales ss ON cs.c_customer_id = ss.c_customer_id
)
SELECT 
    s.c_customer_id,
    s.total_sales,
    s.preferred_channel,
    DENSE_RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    sales_summary s
WHERE 
    (s.total_sales > 5000 OR s.preferred_channel = 'Web')
    AND s.total_sales IS NOT NULL
ORDER BY 
    sales_rank;
