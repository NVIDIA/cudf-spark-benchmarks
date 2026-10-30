
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
store_sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
combined_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales
    FROM 
        customer_sales cs
    FULL OUTER JOIN 
        store_sales_summary ss ON cs.c_customer_sk = ss.c_customer_sk
),
ranked_sales AS (
    SELECT 
        c.*,
        (total_web_sales + total_store_sales) AS total_sales,
        RANK() OVER (ORDER BY (total_web_sales + total_store_sales) DESC) AS sales_rank
    FROM 
        combined_sales c
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_store_sales,
    r.total_sales,
    r.sales_rank,
    CASE 
        WHEN r.total_sales > 1000 THEN 'High Value'
        WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    ranked_sales r
WHERE 
    r.total_sales IS NOT NULL
ORDER BY 
    r.sales_rank;
