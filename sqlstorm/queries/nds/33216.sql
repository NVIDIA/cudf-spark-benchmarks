
WITH  sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 0
),
item_details AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_current_price, 
        COALESCE(sa.total_quantity, 0) AS total_quantity,
        COALESCE(sa.total_profit, 0) AS total_profit
    FROM item i
    LEFT JOIN sales_data sa ON i.i_item_sk = sa.ws_item_sk
),
high_performers AS (
    SELECT 
        id.i_item_sk, 
        id.i_item_desc,
        id.i_current_price, 
        id.total_quantity, 
        id.total_profit,
        CAST((id.total_profit / NULLIF(id.total_quantity, 0)) AS DECIMAL(10, 2)) AS profit_per_item
    FROM item_details id
    WHERE id.total_quantity > 0
)
SELECT 
    hp.i_item_sk, 
    hp.i_item_desc, 
    hp.i_current_price, 
    hp.total_quantity, 
    hp.total_profit, 
    hp.profit_per_item
FROM high_performers hp
WHERE hp.profit_per_item = (
    SELECT MAX(profit_per_item) FROM high_performers
)
ORDER BY hp.total_profit DESC
LIMIT 10;
