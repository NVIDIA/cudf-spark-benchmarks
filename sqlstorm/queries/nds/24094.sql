
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_email_address, cd.cd_gender, cd.cd_marital_status
),
item_profit AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_item_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        ip.ws_item_sk,
        ip.total_item_profit,
        RANK() OVER (ORDER BY ip.total_item_profit DESC) AS item_rank
    FROM 
        item_profit ip
    WHERE 
        ip.total_item_profit > 0
)
SELECT 
    cs.c_customer_sk,
    cs.c_email_address,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_orders,
    cs.total_profit,
    ti.ws_item_sk,
    ti.total_item_profit
FROM 
    customer_stats cs
LEFT JOIN 
    top_items ti ON cs.total_orders > 5 AND (cs.total_profit > 1000 OR cs.total_orders > 10)
WHERE 
    (cs.cd_gender = 'M' AND cs.cd_marital_status IS NOT NULL)
    OR (cs.cd_gender = 'F' AND cs.cd_marital_status = 'S')
ORDER BY 
    cs.total_profit DESC,
    cs.total_orders ASC
LIMIT 100;
