
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_spenders AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_orders,
        rc.total_spent
    FROM ranked_customers rc
    WHERE rc.gender_rank <= 5
)
SELECT 
    ts.c_customer_sk,
    ts.c_first_name,
    ts.c_last_name,
    ts.total_orders,
    ts.total_spent,
    CASE 
        WHEN ts.total_spent IS NULL THEN 'No purchases'
        WHEN ts.total_spent > 1000 THEN 'High spenders'
        ELSE 'Regular spenders'
    END AS spending_category,
    COALESCE(
        (SELECT COUNT(DISTINCT sr_ticket_number) 
         FROM store_returns sr 
         WHERE sr.sr_customer_sk = ts.c_customer_sk), 
         0) AS total_returns
FROM top_spenders ts
ORDER BY ts.total_spent DESC
LIMIT 10;
