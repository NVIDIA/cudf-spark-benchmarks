
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) as total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) as total_transactions
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) as sales_rank
    FROM 
        customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 0
),
ship_modes_stats AS (
    SELECT 
        sm.sm_type,
        COUNT(ws.ws_order_number) as order_count,
        AVG(ws.ws_net_profit) as avg_net_profit
    FROM 
        ship_mode sm
    LEFT JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.sales_rank,
    s.sm_type,
    s.order_count,
    s.avg_net_profit
FROM 
    top_customers tc
CROSS JOIN ship_modes_stats s
WHERE 
    tc.sales_rank <= 10 
    AND (s.avg_net_profit IS NOT NULL OR s.order_count > 0)
ORDER BY 
    tc.total_sales DESC, s.avg_net_profit DESC;
