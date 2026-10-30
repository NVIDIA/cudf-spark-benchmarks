
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_mode_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_ship_mode_sk, ws_item_sk
),
profitability AS (
    SELECT 
        sd.ws_sold_date_sk,
        sm.sm_type,
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_profit,
        RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_profit DESC) AS sales_rank
    FROM sales_data sd
    JOIN ship_mode sm ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_purchases
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.total_purchases,
        CASE 
            WHEN total_purchases IS NULL THEN 'No purchases'
            WHEN total_purchases > 100 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM customer_info ci
    WHERE ci.total_purchases IS NOT NULL OR (ci.total_purchases IS NULL AND ci.cd_gender IS NOT NULL)
),
final_report AS (
    SELECT 
        pv.ws_sold_date_sk,
        hvc.customer_type,
        hvc.cd_gender,
        hvc.cd_marital_status,
        SUM(pv.total_sales) AS sales_total,
        SUM(pv.total_profit) AS profit_total,
        COUNT(DISTINCT pv.ws_item_sk) AS unique_items_sold,
        COALESCE(MAX(pv.sales_rank), 0) AS max_rank
    FROM profitability pv
    JOIN high_value_customers hvc ON pv.ws_sold_date_sk = hvc.c_customer_sk
    GROUP BY pv.ws_sold_date_sk, hvc.customer_type, hvc.cd_gender, hvc.cd_marital_status
)
SELECT 
    f.ws_sold_date_sk,
    f.customer_type,
    f.cd_gender,
    f.cd_marital_status,
    f.sales_total,
    f.profit_total,
    f.unique_items_sold,
    CASE 
        WHEN f.max_rank > 1 THEN 'Highly Engaged'
        ELSE 'Low Engagement'
    END AS engagement_level
FROM final_report f
WHERE f.sales_total > 0
ORDER BY f.ws_sold_date_sk, f.customer_type DESC, f.profit_total DESC;
