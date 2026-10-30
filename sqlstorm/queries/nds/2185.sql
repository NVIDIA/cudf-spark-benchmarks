
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER(PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        customer_info ci
    INNER JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
    WHERE 
        ci.rn = 1
    GROUP BY 
        ci.c_customer_sk
),
avg_profit AS (
    SELECT 
        AVG(total_profit) AS average_profit
    FROM 
        top_customers
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    tc.total_profit,
    (CASE 
        WHEN tc.total_profit > (SELECT average_profit FROM avg_profit) THEN 'Above Average' 
        ELSE 'Below Average' 
    END) AS profit_category
FROM 
    customer_info ci
JOIN 
    top_customers tc ON ci.c_customer_sk = tc.c_customer_sk
WHERE 
    ci.rn = 1
ORDER BY 
    tc.total_profit DESC
LIMIT 10
OFFSET 5;
