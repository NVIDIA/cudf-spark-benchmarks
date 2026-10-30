WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_item_sk
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS store_total_quantity,
        SUM(ss.ss_net_profit) AS store_total_profit
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
CombinedSales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(s.total_quantity, 0) AS web_total_quantity,
        COALESCE(s.total_profit, 0) AS web_total_profit,
        COALESCE(ss.store_total_quantity, 0) AS store_total_quantity,
        COALESCE(ss.store_total_profit, 0) AS store_total_profit
    FROM SalesSummary s
    FULL OUTER JOIN StoreSalesSummary ss ON s.ws_item_sk = ss.ss_item_sk
),
TopProducts AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY web_total_profit DESC) AS rn
    FROM CombinedSales
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tp.web_total_quantity,
    tp.web_total_profit,
    tp.store_total_quantity,
    tp.store_total_profit,
    CASE 
        WHEN tp.web_total_profit > tp.store_total_profit THEN 'Web'
        WHEN tp.web_total_profit < tp.store_total_profit THEN 'Store'
        ELSE 'Equal'
    END AS dominant_channel
FROM TopProducts tp
JOIN item i ON tp.ws_item_sk = i.i_item_sk
WHERE tp.rn <= 100  
ORDER BY tp.web_total_profit DESC;