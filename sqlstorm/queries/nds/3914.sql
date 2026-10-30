
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
popular_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 100
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
    ORDER BY 
        total_net_profit DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    pi.ws_item_sk,
    pi.total_quantity,
    pi.total_profit,
    COALESCE(pi.total_profit / NULLIF(pi.total_quantity, 0), 0) AS avg_profit_per_item,
    ROW_NUMBER() OVER (PARTITION BY tc.c_customer_sk ORDER BY pi.total_profit DESC) AS item_rank
FROM 
    top_customers tc
LEFT JOIN 
    popular_items pi ON tc.c_customer_sk = pi.ws_item_sk 
ORDER BY 
    tc.c_customer_sk, item_rank;
