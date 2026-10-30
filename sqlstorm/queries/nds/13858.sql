
WITH DateRange AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2023
),
ItemStats AS (
    SELECT 
        i_item_sk,
        i_item_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM DateRange)
    GROUP BY i_item_sk, i_item_id
)
SELECT 
    COUNT(*) AS total_items,
    AVG(total_quantity) AS avg_quantity,
    MAX(total_net_profit) AS max_net_profit
FROM ItemStats;
