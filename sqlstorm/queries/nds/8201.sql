WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity_purchased,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders_with_promo,
        SUM(ws.ws_net_paid) AS total_revenue_with_promo
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_quantity_purchased,
    cs.total_spent,
    cs.total_orders,
    ps.total_orders_with_promo,
    ps.total_revenue_with_promo
FROM customer_summary cs
LEFT JOIN promotion_summary ps ON cs.c_customer_sk = ps.total_orders_with_promo
WHERE cs.total_spent > 1000 
ORDER BY cs.total_spent DESC
LIMIT 100;