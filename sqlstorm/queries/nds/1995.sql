
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10.00
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit,
        COALESCE(tr.total_returns, 0) AS total_returns
    FROM 
        RankedSales r
    LEFT JOIN 
        TotalReturns tr ON r.ws_item_sk = tr.sr_item_sk
    WHERE 
        r.rn = 1
)
SELECT 
    s.ws_item_sk,
    s.ws_order_number,
    s.ws_net_profit,
    CASE 
        WHEN s.total_returns > 10 THEN 'High Returns'
        WHEN s.total_returns <= 10 AND s.total_returns > 0 THEN 'Moderate Returns'
        ELSE 'No Returns'
    END AS return_category,
    CONCAT('Item SK: ', s.ws_item_sk, ' | Order Number: ', s.ws_order_number) AS item_info
FROM 
    SalesAndReturns s
WHERE 
    s.ws_net_profit > 0
ORDER BY 
    s.ws_net_profit DESC
LIMIT 10;
