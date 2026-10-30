WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458864 AND 2458929 
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_profit,
        cs.total_orders,
        cs.total_quantity,
        cs.avg_sales_price,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS customer_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.customer_rank,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders,
    tc.total_quantity,
    tc.avg_sales_price,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_profit) AS year_total_net_profit
FROM top_customers tc
JOIN web_sales ws ON tc.c_customer_sk = ws.ws_ship_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE tc.customer_rank <= 10
GROUP BY 
    tc.customer_rank,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders,
    tc.total_quantity,
    tc.avg_sales_price,
    d.d_year
ORDER BY tc.customer_rank;