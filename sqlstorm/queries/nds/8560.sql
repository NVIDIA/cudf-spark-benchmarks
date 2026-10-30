
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459805 AND 2459806 
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_sales,
    CAST('2002-10-01 12:34:56' AS TIMESTAMP) AS query_timestamp
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
