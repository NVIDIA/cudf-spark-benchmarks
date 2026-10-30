WITH  customer_growth AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name,
           cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating,
           COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
             cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
    HAVING COUNT(ws.ws_order_number) > 0
),
customer_ranked AS (
    SELECT *, 
           RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS profit_rank,
           NTILE(4) OVER (ORDER BY total_quantity ASC) AS quantity_quartile
    FROM customer_growth
),
customer_info AS (
    SELECT *,
           CASE 
               WHEN profit_rank = 1 THEN 'Top Profiteer'
               WHEN profit_rank <= 5 THEN 'High Profit'
               ELSE 'Low Profit'
           END AS profit_category,
           CASE 
               WHEN quantity_quartile = 1 THEN 'Low Quantity'
               WHEN quantity_quartile = 4 THEN 'High Quantity'
               ELSE 'Medium Quantity'
           END AS quantity_category
    FROM customer_ranked
),
potential_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           c.c_birth_month, c.c_birth_year, 
           CASE 
               WHEN c.c_first_name IS NULL THEN 'Unknown'
               ELSE c.c_first_name
           END AS name_alias,
           EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year AS age,
           COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
)
SELECT ci.*, pc.name_alias,
       CASE 
           WHEN ci.total_profit < 1000 THEN 'Low Engagement'
           WHEN ci.total_profit BETWEEN 1000 AND 5000 THEN 'Moderate Engagement'
           ELSE 'High Engagement'
       END AS engagement_level
FROM customer_info ci
FULL OUTER JOIN potential_customers pc ON ci.c_customer_sk = pc.c_customer_sk
WHERE (ci.total_profit IS NOT NULL OR pc.purchase_estimate > 0)
AND (ci.order_count IS NULL OR ci.order_count > (SELECT AVG(order_count) FROM customer_growth))
ORDER BY ci.total_profit DESC NULLS LAST, pc.purchase_estimate ASC;