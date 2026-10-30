
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
agg_sales AS (
    SELECT
        s.ws_item_sk,
        s.total_quantity,
        s.total_profit,
        COALESCE(AVG(i.i_current_price), 0) AS avg_price,
        COALESCE(SUM(i.i_wholesale_cost), 0) AS total_wholesale
    FROM 
        sales_data s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    GROUP BY
        s.ws_item_sk, s.total_quantity, s.total_profit
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ab.total_quantity,
    ab.total_profit,
    ab.avg_price,
    ab.total_wholesale,
    CASE WHEN ab.total_quantity > 100 THEN 'High Volume'
         WHEN ab.total_quantity > 50 THEN 'Medium Volume'
         ELSE 'Low Volume' END AS volume_category
FROM 
    customer_info ci
LEFT JOIN 
    agg_sales ab ON ci.c_customer_sk = ab.ws_item_sk
WHERE 
    ci.cd_gender = 'F' AND
    (ci.hd_income_band_sk IS NULL OR ci.hd_income_band_sk > 2)
ORDER BY 
    ab.total_profit DESC
LIMIT 10;
