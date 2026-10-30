
WITH CustomerInfo AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
           cd.cd_marital_status, SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE cd.cd_gender IS NOT NULL AND cd.cd_marital_status IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
SalesRanked AS (
    SELECT c.c_customer_sk AS customer_sk, c.c_first_name AS first_name, c.c_last_name AS last_name, 
           c.cd_gender AS gender, c.cd_marital_status AS marital_status, 
           c.total_quantity, c.total_spent,
           RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_spent DESC) AS rank_by_gender
    FROM CustomerInfo c
)
SELECT 
    s.customer_sk,
    s.first_name || ' ' || s.last_name AS full_name,
    s.gender,
    s.marital_status,
    s.total_quantity,
    COALESCE(s.total_spent, 0.00) AS total_spent,
    CASE 
        WHEN s.rank_by_gender = 1 THEN 'Top Spender'
        WHEN s.rank_by_gender <= 5 THEN 'Top 5 Spenders'
        ELSE 'Regular Spender'
    END AS spender_category
FROM SalesRanked s
LEFT JOIN (
    SELECT ws_bill_customer_sk, COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
) AS order_counts ON s.customer_sk = order_counts.ws_bill_customer_sk
WHERE order_counts.distinct_orders > 2 OR order_counts.ws_bill_customer_sk IS NULL
ORDER BY s.gender, s.total_spent DESC;
