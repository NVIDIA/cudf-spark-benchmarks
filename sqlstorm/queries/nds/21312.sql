
WITH ranked_sales AS (
    SELECT 
        ss_item_sk,
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2020)
    GROUP BY ss_item_sk, ss_store_sk, ss_sold_date_sk
),
top_stores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(total_net_profit) AS total_store_profit
    FROM ranked_sales
    JOIN store ON ranked_sales.ss_store_sk = store.s_store_sk
    WHERE rank <= 3
    GROUP BY s_store_sk, s_store_name
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        CASE 
            WHEN COUNT(DISTINCT ws_order_number) = 0 THEN 'No Orders'
            WHEN COUNT(DISTINCT ws_order_number) BETWEEN 1 AND 5 THEN 'Few Orders'
            ELSE 'Many Orders'
        END AS order_category
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
),
customer_income AS (
    SELECT 
        c.c_customer_sk,
        MAX(hd.hd_income_band_sk) AS max_income_band,
        MIN(hd.hd_income_band_sk) AS min_income_band
    FROM customer c
    JOIN household_demographics hd ON c.c_current_cdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.order_category,
    ci.max_income_band,
    ci.min_income_band,
    ts.total_store_profit
FROM customer_stats cs
JOIN customer_income ci ON cs.c_customer_sk = ci.c_customer_sk
LEFT JOIN top_stores ts ON ci.max_income_band = ts.s_store_sk
WHERE 
    (cs.order_category = 'No Orders' AND ci.max_income_band IS NULL)
    OR (cs.order_category <> 'No Orders' AND ci.max_income_band IS NOT NULL)
ORDER BY cs.c_customer_sk;
