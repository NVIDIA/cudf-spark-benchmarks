
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit > 0
),
top_sales AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_net_profit) AS total_net_profit
    FROM 
        ranked_sales r
    WHERE 
        r.rn <= 5
    GROUP BY 
        r.ws_item_sk
),
low_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        SUM(inv.inv_quantity_on_hand) < 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
returns_data AS (
    SELECT 
        coalesce(sr.sr_item_sk, wr.wr_item_sk) as item_sk,
        count(distinct sr.sr_ticket_number) as store_returns,
        count(distinct wr.wr_order_number) as web_returns
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        web_returns wr ON sr.sr_item_sk = wr.wr_item_sk
    GROUP BY 
        coalesce(sr.sr_item_sk, wr.wr_item_sk)
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(inv.total_quantity, 0) AS total_inventory,
    COALESCE(ts.total_net_profit, 0) AS total_profit,
    COALESCE(rd.store_returns, 0) AS return_count
FROM 
    customer_info ci
LEFT JOIN 
    top_sales ts ON ci.c_customer_sk = ts.ws_item_sk
LEFT JOIN 
    low_inventory inv ON ts.ws_item_sk = inv.inv_item_sk
LEFT JOIN 
    returns_data rd ON ts.ws_item_sk = rd.item_sk
WHERE 
    (ci.cd_gender IS NULL OR ci.cd_gender = 'F')
    AND (ci.cd_marital_status IS NOT NULL)
    AND (inv.total_quantity IS NULL OR inv.total_quantity < 5)
ORDER BY 
    total_profit DESC, ci.c_last_name ASC
LIMIT 100;
