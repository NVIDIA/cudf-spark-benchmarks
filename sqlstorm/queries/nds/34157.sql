
WITH  sales_data AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit, 
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_order_number, 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk, 
        total_profit, 
        order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY total_profit DESC) AS profit_rank
    FROM 
        sales_data
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
)
SELECT 
    t.ws_item_sk,
    t.total_profit,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_item_sk = t.ws_item_sk) AS store_sales_count,
    COALESCE(t.order_count, 0) AS online_sales_count,
    (SELECT SUM(sr_return_quantity) 
     FROM store_returns sr 
     WHERE sr.sr_item_sk = t.ws_item_sk) AS total_store_returns
FROM 
    top_sales t
LEFT JOIN 
    customer_info c ON t.ws_item_sk = c.c_customer_sk
WHERE 
    t.profit_rank <= 10
ORDER BY 
    t.total_profit DESC, 
    c.cd_purchase_estimate DESC;
