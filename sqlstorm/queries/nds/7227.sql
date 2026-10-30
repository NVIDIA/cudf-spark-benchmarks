
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        MIN(ws.ws_sold_date_sk) AS first_order_date,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM customer_sales cs
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_spent,
    t.sales_rank,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_paid_with_tax,
    AVG(ws.ws_net_profit) AS avg_profit
FROM top_customers t
JOIN web_sales ws ON t.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE t.sales_rank <= 10
GROUP BY t.c_customer_sk, t.c_first_name, t.c_last_name, t.total_spent, t.sales_rank, d.d_year
ORDER BY t.sales_rank, t.total_spent DESC;
