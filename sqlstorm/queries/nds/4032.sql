
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_return_quantity
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
HighReturnItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_profit,
        rs.total_quantity,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.cr_item_sk
    WHERE 
        rs.rank_profit <= 10
)
SELECT 
    hi.ws_item_sk,
    hi.total_quantity,
    hi.total_profit,
    hi.total_returns,
    hi.total_return_amount,
    (hi.total_profit - hi.total_return_amount) AS net_profit_after_returns,
    CASE 
        WHEN hi.total_returns > 0 THEN 'High Return'
        WHEN hi.total_profit < 0 THEN 'Loss Item'
        ELSE 'Regular Profit Item'
    END AS item_status
FROM 
    HighReturnItems hi
ORDER BY 
    hi.total_profit DESC;
