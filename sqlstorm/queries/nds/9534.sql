WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 24520 AND 24550  
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT
        ws_item_sk,
        SUM(total_quantity) AS total_quantity,
        SUM(total_net_profit) AS total_net_profit
    FROM RankedSales
    WHERE rank <= 5
    GROUP BY ws_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit
FROM TopItems ti
JOIN item i ON ti.ws_item_sk = i.i_item_sk
ORDER BY ti.total_net_profit DESC;