
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_item_sk
), 
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month,
        d.d_year,
        cd.cd_gender,
        cd.cd_dep_count,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
), 
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        SUM(ss.total_net_profit) AS total_spent
    FROM sales_summary ss
    JOIN customer_summary cs ON ss.ws_item_sk IN (
        SELECT inv.inv_item_sk
        FROM inventory inv
        WHERE inv.inv_quantity_on_hand > 0
    )
    GROUP BY cs.c_customer_sk
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT
    cu.c_customer_sk,
    cu.c_birth_month,
    cu.cd_gender,
    cu.cd_dep_count,
    cu.cd_marital_status,
    COALESCE(ts.total_spent, 0) AS total_spent_last_30_days
FROM customer_summary cu
LEFT JOIN top_customers ts ON cu.c_customer_sk = ts.c_customer_sk
WHERE cu.cd_dep_count IS NOT NULL
AND cu.cd_marital_status = 'M'
ORDER BY total_spent_last_30_days DESC
LIMIT 20;
