WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
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
    tc.c_customer_id,
    tc.total_sales,
    tc.sales_rank,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales' 
        WHEN tc.total_sales < 1000 THEN 'Low Spending' 
        ELSE 'High Spending' 
    END AS spending_category,
    COALESCE((
        SELECT 
            COUNT(sr.sr_ticket_number) 
        FROM 
            store_returns sr 
        WHERE 
            sr.sr_customer_sk = c.c_customer_sk
    ), 0) AS return_count
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;