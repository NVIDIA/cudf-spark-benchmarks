
WITH  top_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
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
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS marital_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
latest_stores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        MAX(s.s_rec_start_date) AS latest_start
    FROM 
        store s
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
sales_per_store AS (
    SELECT 
        s.s_store_sk,
        SUM(ws.ws_net_profit) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        store s ON ws.ws_warehouse_sk = s.s_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ts.total_net_profit,
    ci.marital_rank,
    ls.s_store_name,
    COALESCE(sp.total_sales, 0) AS store_profit
FROM 
    customer_info ci
JOIN 
    top_sales ts ON ts.ws_item_sk = (SELECT ws_item_sk FROM web_sales ORDER BY ws_net_profit DESC LIMIT 1)
JOIN 
    latest_stores ls ON ls.s_store_sk = (SELECT s_store_sk FROM store ORDER BY s_rec_start_date DESC LIMIT 1)
LEFT JOIN 
    sales_per_store sp ON sp.s_store_sk = ls.s_store_sk
WHERE 
    ci.marital_rank <= 5
ORDER BY 
    ts.total_net_profit DESC, ci.c_last_name;
