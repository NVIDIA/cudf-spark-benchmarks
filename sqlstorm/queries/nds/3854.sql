
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(*) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM store_returns
    GROUP BY sr_item_sk
),
TopReturnedItems AS (
    SELECT 
        r.sr_item_sk,
        r.total_returned,
        r.return_count,
        it.i_item_desc,
        it.i_current_price
    FROM RankedReturns r
    JOIN item it ON r.sr_item_sk = it.i_item_sk
    WHERE r.rn <= 10
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT 
    T.i_item_desc AS item_desc,
    COALESCE(T.total_returned, 0) AS total_returned,
    COALESCE(S.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(S.total_sales, 0) AS total_sales,
    COALESCE(S.avg_net_profit, 0) AS avg_net_profit,
    CASE
        WHEN COALESCE(S.total_sales, 0) > 0 THEN (COALESCE(T.total_returned, 0) * 100.0 / COALESCE(S.total_quantity_sold, 1))
        ELSE NULL
    END AS return_percentage
FROM 
    TopReturnedItems T
LEFT JOIN 
    SalesData S ON T.sr_item_sk = S.ws_item_sk
ORDER BY 
    return_percentage DESC;
