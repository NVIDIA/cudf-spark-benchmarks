
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
), profitable_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_net_profit
    FROM 
        ranked_sales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rank_net_profit <= 10
), customer_stats AS (
    SELECT 
        cd.cd_gender AS gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_moy = 1 LIMIT 1) 
                             AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_moy = 12 LIMIT 1)
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cs.gender,
    SUM(p.total_quantity) AS total_items_sold,
    SUM(p.total_net_profit) AS total_profit
FROM 
    profitable_items p
JOIN 
    customer_stats cs ON p.i_item_desc = cs.gender
GROUP BY 
    cs.gender
ORDER BY 
    total_profit DESC
LIMIT 5;
