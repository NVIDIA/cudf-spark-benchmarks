
WITH  sales_trend AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk 
    HAVING SUM(ws_net_profit) > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status 
    HAVING SUM(ws.ws_net_profit) IS NOT NULL
),
store_warehouse AS (
    SELECT 
        s.s_store_sk, 
        w.w_warehouse_name,
        SUM(ss.ss_sales_price) AS total_sales
    FROM store s
    JOIN warehouse w ON s.s_store_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, w.w_warehouse_name
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    si.w_warehouse_name,
    si.total_sales,
    st.total_profit,
    ci.total_orders,
    ci.total_spent,
    CASE 
        WHEN ci.total_spent IS NULL THEN 'No Purchases'
        WHEN ci.total_spent < 500 THEN 'Low'
        WHEN ci.total_spent >= 500 AND ci.total_spent < 1000 THEN 'Medium'
        ELSE 'High'
    END AS spending_level
FROM customer_info ci
JOIN store_warehouse si ON ci.c_customer_sk = si.s_store_sk
LEFT JOIN sales_trend st ON st.ws_sold_date_sk = ci.total_orders
WHERE ci.cd_gender IS NOT NULL 
ORDER BY ci.total_spent DESC, st.total_profit DESC
LIMIT 100;
