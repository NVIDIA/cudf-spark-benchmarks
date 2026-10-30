
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS OverallRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
TopProfitableItems AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.ProfitRank = 1
),
ReturnInfo AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturns,
        SUM(sr_return_amt) AS TotalReturnAmount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(tpi.ws_net_profit, 0) AS BestNetProfit,
        COALESCE(ri.TotalReturns, 0) AS ReturnQuantity,
        COALESCE(ri.TotalReturnAmount, 0) AS ReturnAmount,
        CASE 
            WHEN COALESCE(ri.TotalReturns, 0) = 0 THEN 'No Returns'
            ELSE 'Returned'
        END AS ReturnStatus
    FROM 
        item i 
    LEFT JOIN 
        TopProfitableItems tpi ON i.i_item_sk = tpi.ws_item_sk
    LEFT JOIN 
        ReturnInfo ri ON i.i_item_sk = ri.sr_item_sk
)
SELECT 
    i_item_id,
    BestNetProfit,
    ReturnQuantity,
    ReturnAmount,
    ReturnStatus
FROM 
    ItemSummary
WHERE 
    (BestNetProfit > 1000 OR ReturnQuantity > 5)
    AND (ReturnStatus = 'Returned' OR BestNetProfit IS NULL)
ORDER BY 
    BestNetProfit DESC, 
    ReturnQuantity DESC;
