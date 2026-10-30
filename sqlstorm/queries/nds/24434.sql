
WITH 
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM customer AS c
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_purchases,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank,
        ntile(4) OVER (ORDER BY cs.total_spent) AS quartile
    FROM customer_sales AS cs
),
promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS related_orders
    FROM promotion AS p
    LEFT JOIN web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name
)
SELECT 
    sa.c_first_name,
    sa.c_last_name,
    COALESCE(sa.total_spent, 0) AS total_spent,
    COALESCE(sa.total_purchases, 0) AS total_purchases,
    sa.spending_rank,
    pa.related_orders,
    CASE 
        WHEN sa.quartile = 1 THEN 'Low Spender'
        WHEN sa.quartile = 2 THEN 'Moderate Spender'
        WHEN sa.quartile = 3 THEN 'High Spender'
        WHEN sa.quartile = 4 THEN 'Top Spender'
    END AS spending_category
FROM sales_analysis AS sa
FULL OUTER JOIN promotions AS pa ON sa.c_customer_sk = pa.p_promo_sk
WHERE (sa.total_spent > 1000 OR pa.related_orders IS NOT NULL)
  AND (sa.c_last_name IS NOT NULL AND sa.c_last_name LIKE '%s%')
ORDER BY sa.spending_rank DESC, sa.total_spent DESC
LIMIT 100;
