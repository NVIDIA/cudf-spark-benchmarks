
WITH  sales_cte AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
inventory_summary AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_date_sk) AS total_days_counted
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
),
join_results AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        isum.total_quantity,
        isum.total_days_counted,
        CASE
            WHEN cs.total_spent IS NULL THEN 'No Purchases'
            WHEN cs.total_orders < 5 THEN 'Low Activity'
            ELSE 'High Activity'
        END AS activity_level
    FROM customer_stats cs
    JOIN inventory_summary isum ON cs.c_customer_sk % 10 = isum.inv_warehouse_sk  
)
SELECT
    jr.c_customer_sk,
    jr.c_first_name,
    jr.c_last_name,
    COALESCE(jr.total_spent, 0) AS total_spent,
    COALESCE(jr.total_orders, 0) AS total_orders,
    jr.total_quantity,
    jr.total_days_counted,
    jr.activity_level,
    ROW_NUMBER() OVER (ORDER BY COALESCE(jr.total_spent, 0) DESC) AS ranked_customers
FROM join_results jr
WHERE jr.total_quantity IS NOT NULL
ORDER BY ranked_customers
LIMIT 100;
