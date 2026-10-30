
WITH  sales_cte AS (
    SELECT 
        ws_item_sk, 
        ws_sold_date_sk, 
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_sold_date_sk,
        cs_quantity,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) as rn
    FROM 
        catalog_sales
),
top_sales AS (
    SELECT 
        sales_cte.ws_item_sk AS item_sk,
        SUM(sales_cte.ws_quantity) AS total_quantity,
        SUM(sales_cte.ws_net_profit) AS total_profit
    FROM 
        sales_cte
    WHERE 
        rn <= 5
    GROUP BY 
        sales_cte.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ts.total_quantity,
    ts.total_profit,
    ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ts.total_profit DESC) AS gender_rank
FROM 
    customer_info ci
JOIN 
    top_sales ts ON ci.c_customer_sk = ts.item_sk
WHERE 
    ci.cd_purchase_estimate IS NOT NULL
ORDER BY 
    gender_rank, ts.total_profit DESC
LIMIT 100;
