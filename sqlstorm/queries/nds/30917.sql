
WITH  sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        CASE 
            WHEN SUM(ws_ext_sales_price) IS NULL THEN 'NO SPENDING'
            WHEN SUM(ws_ext_sales_price) > 500 THEN 'HIGH SPENDER'
            ELSE 'LOW SPENDER'
        END AS spending_category
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS ranking
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
    HAVING SUM(ws_ext_sales_price) > 1000
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.spending_category,
    ti.i_item_desc,
    ti.total_sales,
    COALESCE(s.total_net_profit, 0) AS total_net_profit
FROM customer_summary cs
LEFT JOIN top_items ti ON cs.total_orders > 5
LEFT JOIN sales_cte s ON ti.i_item_sk = s.ws_item_sk AND s.rank = 1
WHERE cs.total_spent IS NOT NULL
ORDER BY cs.total_spent DESC, ti.total_sales DESC;
