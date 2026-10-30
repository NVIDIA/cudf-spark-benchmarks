
WITH  sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit, 
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
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
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk 
    WHERE 
        c.c_birth_year IS NOT NULL
),
temp AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        sd.total_profit,
        sd.order_count,
        CASE 
            WHEN sd.total_profit > 1000 THEN 'High'
            WHEN sd.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM 
        customer_info ci
    JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
    WHERE 
        ci.gender_rank <= 10
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.cd_gender,
    t.total_profit,
    t.order_count,
    t.profit_category
FROM 
    temp t
WHERE 
    (t.total_profit IS NOT NULL AND t.order_count > 5)
UNION ALL
SELECT 
    'Total' AS c_first_name, 
    NULL AS c_last_name, 
    NULL AS cd_gender, 
    SUM(total_profit) AS total_profit, 
    SUM(order_count) AS order_count, 
    NULL AS profit_category
FROM 
    temp
HAVING 
    SUM(total_profit) > 2000
ORDER BY 
    total_profit DESC;
