
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        sd.profit_rank,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        COALESCE((SELECT MAX(ws_net_profit) 
                  FROM web_sales 
                  WHERE ws_item_sk = sd.ws_item_sk
                  AND ws_net_profit > 0), 0) AS max_profit
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.profit_rank <= 10
)
SELECT 
    rs.ws_item_sk,
    rs.total_quantity,
    rs.total_profit,
    rs.max_profit,
    i.i_category,
    COUNT(DISTINCT ws_order_number) AS order_count,
    AVG(ws_net_paid_inc_tax) AS avg_order_value,
    SUM(NULLIF(ws_net_profit, 0)) AS adjusted_profit
FROM 
    ranked_sales rs
JOIN 
    web_sales ws ON rs.ws_item_sk = ws.ws_item_sk
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
WHERE 
    i.i_category IN (SELECT DISTINCT i_category FROM item WHERE i_brand LIKE 'Brand A%')
GROUP BY 
    rs.ws_item_sk, rs.total_quantity, rs.total_profit, rs.max_profit, i.i_category
HAVING 
    SUM(ws_quantity) > 100
ORDER BY 
    adjusted_profit DESC;
