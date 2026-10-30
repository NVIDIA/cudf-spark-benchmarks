
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
store_sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cs.total_web_sales, 0) AS web_sales,
    COALESCE(sss.total_store_sales, 0) AS store_sales,
    (COALESCE(cs.total_web_sales, 0) + COALESCE(sss.total_store_sales, 0)) AS total_sales,
    CASE 
        WHEN cs.total_web_sales IS NULL THEN 'No Web Sales'
        WHEN cs.web_order_count > 0 AND sss.store_order_count > 0 THEN 'Both Store and Web'
        WHEN cs.web_order_count = 0 AND sss.store_order_count = 0 THEN 'No Sales'
        ELSE 'Only Store Sales'
    END AS sales_category
FROM 
    customer_sales cs
FULL OUTER JOIN 
    store_sales_summary sss ON cs.c_customer_sk = sss.s_store_sk
WHERE 
    (COALESCE(cs.total_web_sales, 0) > 500 OR COALESCE(sss.total_store_sales, 0) > 500)
    AND (cs.sales_rank <= 100 OR cs.c_customer_sk IS NULL)
ORDER BY 
    total_sales DESC;
