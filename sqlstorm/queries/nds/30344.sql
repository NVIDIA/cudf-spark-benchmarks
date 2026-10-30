
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(ss.ss_net_paid, 0) AS total_store_sales,
        COALESCE(ws.ws_net_paid, 0) AS total_web_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        SUM(cs.total_store_sales) AS total_store_sales,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_store_sales + cs.total_web_sales) AS grand_total_sales
    FROM 
        customer_sales cs
    WHERE 
        cs.sales_rank <= 5
    GROUP BY 
        cs.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 1000
)
SELECT 
    c.c_customer_id,
    COALESCE(ohv.total_store_sales, 0) AS store_sales,
    COALESCE(ohv.total_web_sales, 0) AS web_sales,
    COALESCE(ohv.total_store_sales, 0) + COALESCE(ohv.total_web_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(ohv.total_store_sales, 0) = 0 THEN 'No Store Sales'
        WHEN COALESCE(ohv.total_web_sales, 0) = 0 THEN 'No Web Sales'
        ELSE 'Both Channels'
    END AS sales_channel
FROM 
    customer c
LEFT JOIN 
    high_value_customers ohv ON c.c_customer_id = ohv.c_customer_id
ORDER BY 
    total_sales DESC;
