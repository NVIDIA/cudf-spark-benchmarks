
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS spend_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        cs.spend_rank
    FROM customer_summary cs
    WHERE cs.spend_rank <= 10
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
    FROM warehouse w
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    wi.w_warehouse_name,
    wi.w_city,
    wi.w_state,
    CASE 
        WHEN tc.total_spent > 1000 THEN 'High Value'
        WHEN tc.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    (SELECT COUNT(DISTINCT ws.ws_order_number) FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS distinct_orders,
    COALESCE((SELECT MAX(ss.ss_net_profit) FROM store_sales ss WHERE ss.ss_customer_sk = tc.c_customer_sk), 0) AS max_store_profit
FROM top_customers tc
LEFT JOIN warehouse_info wi ON tc.c_customer_sk = wi.w_warehouse_sk
ORDER BY tc.total_spent DESC;
