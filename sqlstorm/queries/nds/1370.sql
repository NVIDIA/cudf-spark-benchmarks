
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                          AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_customer
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
top_sales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit,
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name
    FROM 
        ranked_sales r
    JOIN 
        customer_info ci ON r.ws_order_number = ci.c_customer_sk
    WHERE 
        r.rank_profit <= 10
)
SELECT 
    t.ws_item_sk,
    t.ws_order_number,
    t.ws_net_profit,
    t.c_first_name,
    t.c_last_name,
    COALESCE(i.i_product_name, 'N/A') AS product_name,
    SUM(COALESCE(s.cs_quantity, 0)) AS catalog_sales_quantity,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_returns
FROM 
    top_sales t
LEFT JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
LEFT JOIN 
    catalog_sales s ON t.ws_item_sk = s.cs_item_sk
LEFT JOIN 
    store_returns sr ON t.ws_order_number = sr.sr_ticket_number
GROUP BY 
    t.ws_item_sk, 
    t.ws_order_number, 
    t.ws_net_profit, 
    t.c_first_name, 
    t.c_last_name, 
    i.i_product_name
HAVING 
    SUM(COALESCE(s.cs_quantity, 0)) > 0 
    AND t.ws_net_profit > 500
ORDER BY 
    t.ws_net_profit DESC;
