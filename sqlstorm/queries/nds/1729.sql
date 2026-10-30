
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns cr ON r.ws_item_sk = cr.wr_item_sk
)
SELECT 
    sar.ws_item_sk,
    sar.total_quantity,
    sar.total_profit,
    sar.total_returns,
    sar.total_return_amount,
    (sar.total_profit - sar.total_return_amount) AS net_profit_after_returns
FROM 
    SalesAndReturns sar
WHERE 
    sar.total_profit > 1000 AND 
    sar.total_quantity > 50
ORDER BY 
    net_profit_after_returns DESC
LIMIT 10;
