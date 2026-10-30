WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450814 AND 2450814 + 30 
    GROUP BY ws_item_sk
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year > 1980 
    GROUP BY c.c_customer_sk
),
most_profitable_items AS (
    SELECT
        rs.ws_item_sk,
        ci.i_item_desc,
        rs.total_net_profit,
        cs.order_count
    FROM ranked_sales rs
    JOIN item ci ON rs.ws_item_sk = ci.i_item_sk
    JOIN customer_stats cs ON cs.order_count > 5
    WHERE rs.rank <= 5
)
SELECT
    mpi.i_item_desc,
    mpi.total_net_profit,
    COALESCE(cs.order_count, 0) AS total_orders
FROM most_profitable_items mpi
LEFT JOIN customer_stats cs ON cs.avg_spent > 1000
ORDER BY mpi.total_net_profit DESC;