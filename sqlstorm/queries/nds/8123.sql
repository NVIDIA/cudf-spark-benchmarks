
WITH customer_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cs.total_sales,
        cs.order_count,
        cs.avg_net_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    tc.avg_net_profit
FROM 
    top_customers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_sales DESC;
