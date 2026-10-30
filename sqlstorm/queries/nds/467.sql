
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_quantity, 
        rs.total_profit,
        i.i_item_desc
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank_profit <= 10
),
SalesAndReturns AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_profit,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns
    FROM 
        TopSales ts
    LEFT JOIN 
        store_returns sr ON ts.ws_item_sk = sr.sr_item_sk
    GROUP BY 
        ts.ws_item_sk, ts.total_quantity, ts.total_profit
)
SELECT 
    sa.ws_item_sk,
    i.i_item_desc,
    sa.total_quantity,
    sa.total_profit,
    sa.total_returns,
    (sa.total_profit - sa.total_returns) AS net_profit_after_returns,
    CASE 
        WHEN sa.total_returns = 0 THEN 'No Returns'
        WHEN sa.total_returns < sa.total_quantity THEN 'Partial Returns'
        ELSE 'Full Returns'
    END AS return_status
FROM 
    SalesAndReturns sa
JOIN 
    item i ON sa.ws_item_sk = i.i_item_sk
WHERE 
    (sa.total_profit - sa.total_returns) > 1000
ORDER BY 
    net_profit_after_returns DESC
LIMIT 20;
