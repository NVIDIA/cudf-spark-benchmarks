
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_sales AS (
    SELECT 
        sd.total_quantity,
        sd.total_profit,
        ci.c_first_name,
        ci.c_last_name,
        sd.ws_sold_date_sk
    FROM 
        sales_data sd
    INNER JOIN customer_info ci ON sd.ws_item_sk = ci.c_customer_sk
    WHERE 
        sd.rank_profit <= 10
)
SELECT 
    hi.c_first_name,
    hi.c_last_name,
    hi.total_quantity,
    hi.total_profit,
    nd.d_date AS sales_date
FROM 
    high_value_sales hi
JOIN 
    date_dim nd ON hi.ws_sold_date_sk = nd.d_date_sk
WHERE 
    nd.d_year = 2001 AND 
    hi.total_profit IS NOT NULL
ORDER BY 
    hi.total_profit DESC
LIMIT 10 OFFSET 5;
