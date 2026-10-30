
WITH ranked_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1980
      AND (cd.cd_marital_status IS NOT NULL OR cd.cd_gender = 'F')
),
agg_sales AS (
    SELECT ws_bill_customer_sk,
           COUNT(ws_order_number) AS total_orders,
           SUM(ws_net_profit) AS total_profit,
           AVG(ws_net_paid) AS avg_paid
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk
),
common_customers AS (
    SELECT DISTINCT rc.c_customer_sk
    FROM ranked_customers rc
    JOIN agg_sales a ON rc.c_customer_sk = a.ws_bill_customer_sk
    WHERE rc.purchase_rank <= 10
)
SELECT rc.c_first_name,
       rc.c_last_name,
       COALESCE(a.total_orders, 0) AS order_count,
       COALESCE(a.total_profit, 0) AS total_profit,
       CASE 
           WHEN a.avg_paid > 100 THEN 'High Value'
           WHEN a.avg_paid IS NULL THEN 'No Purchases'
           ELSE 'Regular'
       END AS customer_value_type
FROM ranked_customers rc
LEFT JOIN agg_sales a ON rc.c_customer_sk = a.ws_bill_customer_sk
WHERE rc.c_customer_sk IN (SELECT c_customer_sk FROM common_customers)
ORDER BY rc.c_last_name, rc.c_first_name;
