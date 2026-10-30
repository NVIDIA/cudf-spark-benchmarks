
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_summary AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM web_sales
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    GROUP BY c_customer_sk
),
highvalue_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM customer_summary cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cs.total_spent IS NOT NULL
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_net_profit
    FROM sales_summary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE ss.rank_profit <= 10
)
SELECT 
    hc.c_customer_sk,
    hc.total_orders,
    hc.total_spent,
    hc.cd_gender,
    hc.cd_marital_status,
    hc.customer_type,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit
FROM highvalue_customers hc
LEFT JOIN top_items ti ON hc.total_spent > 500
WHERE hc.total_orders > 5 AND hc.cd_marital_status IS NOT NULL
ORDER BY hc.total_spent DESC, ti.total_net_profit DESC
LIMIT 100;
