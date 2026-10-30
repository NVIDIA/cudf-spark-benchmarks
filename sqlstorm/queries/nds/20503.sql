
WITH  customer_purchase_history AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name
    HAVING SUM(ws.ws_net_paid) IS NOT NULL
),
ranked_customers AS (
    SELECT 
        cph.c_customer_sk,
        cph.c_first_name,
        cph.total_orders,
        cph.total_spent,
        RANK() OVER (ORDER BY cph.total_spent DESC) AS ranking
    FROM customer_purchase_history cph
),
rich_customers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name,
        rc.total_orders,
        rc.total_spent,
        CASE 
            WHEN rc.total_spent > 1000 THEN 'Platinum' 
            WHEN rc.total_spent BETWEEN 500 AND 1000 THEN 'Gold' 
            ELSE 'Silver' 
        END AS customer_tier
    FROM ranked_customers rc
    WHERE rc.total_orders > 5
),
top_customers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name,
        rc.customer_tier,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM rich_customers rc
    LEFT JOIN store_returns sr ON rc.c_customer_sk = sr.sr_customer_sk
    GROUP BY rc.c_customer_sk, rc.c_first_name, rc.customer_tier
    HAVING COUNT(sr.sr_ticket_number) IS NULL OR COUNT(sr.sr_ticket_number) < 3
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.customer_tier,
    tc.total_returns,
    CASE 
        WHEN tc.total_returns > 2 THEN 'Frequent Returner' 
        ELSE 'Rare Returner' 
    END AS return_behavior
FROM top_customers tc
LEFT JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN (
    SELECT 
        d.d_year,
        AVG(ws.ws_net_paid) AS avg_spending
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2018 AND 2022
    GROUP BY d.d_year
) yearly_avg ON yearly_avg.avg_spending IS NOT NULL
WHERE 
    (cd.cd_marital_status = 'S' OR cd.cd_credit_rating IS NULL)
    AND (tc.total_returns > yearly_avg.avg_spending OR yearly_avg.avg_spending IS NULL)
ORDER BY tc.customer_tier DESC, tc.total_returns ASC;
