
WITH customer_summary AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
           DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
), high_spenders AS (
    SELECT c.c_customer_sk, 
           cs.total_orders, 
           cs.total_spent,
           case when cs.gender_rank <= 5 then 'Top 5%' 
                when cs.total_spent > 1000 then 'High Spender' 
                else 'Regular' end AS spender_category
    FROM customer_summary cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
), recent_orders AS (
    SELECT ws.ws_bill_customer_sk, 
           COUNT(ws.ws_order_number) AS recent_orders_count,
           SUM(ws.ws_sales_price) AS recent_total_spent
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date >= '2023-01-01')
    GROUP BY ws.ws_bill_customer_sk
)
SELECT cs.c_customer_sk,
       cs.c_first_name,
       cs.c_last_name,
       cs.gender_rank,
       hs.spender_category,
       hs.total_orders,
       hs.total_spent,
       COALESCE(ro.recent_orders_count, 0) AS recent_orders_count,
       COALESCE(ro.recent_total_spent, 0) AS recent_total_spent
FROM customer_summary cs
JOIN high_spenders hs ON cs.c_customer_sk = hs.c_customer_sk
LEFT JOIN recent_orders ro ON cs.c_customer_sk = ro.ws_bill_customer_sk
WHERE cs.total_spent > 0
ORDER BY cs.total_spent DESC
LIMIT 100;
