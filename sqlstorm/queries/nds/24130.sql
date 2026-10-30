
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS revenue_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_net_profit,
        cs.total_orders,
        CASE 
            WHEN cs.total_net_profit IS NULL THEN 'N/A'
            WHEN cs.total_net_profit > 1000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_type
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_orders > 5
),
daily_sales AS (
    SELECT
        dd.d_date,
        SUM(ws.ws_net_profit) AS daily_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS daily_order_count
    FROM date_dim dd
    LEFT JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY dd.d_date
)
SELECT 
    hvc.c_customer_id,
    hvc.total_net_profit,
    hvc.total_orders,
    hvc.customer_type,
    ds.daily_net_profit,
    COALESCE(ds.daily_order_count, 0) AS daily_order_count,
    RANK() OVER (ORDER BY hvc.total_net_profit DESC) AS overall_rank,
    ROW_NUMBER() OVER (PARTITION BY hvc.customer_type ORDER BY hvc.total_net_profit DESC) AS type_rank,
    CASE 
        WHEN hvc.total_net_profit IS NOT NULL THEN 
            hvc.total_net_profit * 0.10 
        ELSE 
            NULL 
    END AS potential_bonus
FROM high_value_customers hvc
LEFT JOIN daily_sales ds ON hvc.total_orders = ds.daily_order_count
WHERE hvc.customer_type <> 'Regular'
OR (hvc.total_net_profit IS NULL AND hvc.total_orders < 3)
ORDER BY overall_rank, type_rank;
