
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
date_sales AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year
), 
inventory_data AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        MIN(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS min_quantity,
        MAX(inv.inv_quantity_on_hand) AS max_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
customer_sales AS (
    SELECT 
        rc.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM ranked_customers rc
    LEFT JOIN web_sales ws ON rc.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY rc.c_customer_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.total_orders, 
    cs.total_spent, 
    ds.total_profit,
    COALESCE(NULLIF(cs.total_spent - ds.total_profit, 0), -1) AS adjusted_profit,
    CASE 
        WHEN cs.total_orders IS NULL THEN 'No Orders' 
        WHEN cs.total_orders > 10 THEN 'Frequent Shopper' 
        ELSE 'Occasional Buyer' 
    END AS customer_type,
    CASE 
        WHEN EXISTS (SELECT 1 
                     FROM reason r 
                     WHERE r.r_reason_sk IN (1, 2, 3)) 
        THEN 'Reason Exists' 
        ELSE 'No Valid Reason' 
    END AS reason_status
FROM customer_sales cs
FULL OUTER JOIN date_sales ds ON cs.c_customer_sk IS NOT NULL
WHERE (cs.total_spent IS NOT NULL AND ds.total_profit IS NOT NULL)
  OR (cs.c_customer_sk IS NULL AND ds.total_profit IS NOT NULL)
ORDER BY adjusted_profit DESC, cs.total_orders DESC;
