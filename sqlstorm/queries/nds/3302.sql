
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM store_returns
    GROUP BY sr_item_sk
),
HighReturnItems AS (
    SELECT 
        rr.sr_item_sk,
        rr.total_returned,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price
    FROM RankedReturns rr
    JOIN item i ON rr.sr_item_sk = i.i_item_sk
    WHERE rr.return_rank <= 10
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
StoreSalesData AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
TotalSales AS (
    SELECT 
        COALESCE(ws.ws_item_sk, ss.ss_item_sk) AS item_sk,
        COALESCE(ws.total_sales, 0) + COALESCE(ss.total_store_sales, 0) AS combined_sales,
        COALESCE(ws.total_profit, 0) + COALESCE(ss.total_store_profit, 0) AS combined_profit
    FROM SalesData ws
    FULL OUTER JOIN StoreSalesData ss ON ws.ws_item_sk = ss.ss_item_sk
)
SELECT 
    hri.i_item_id,
    hri.i_item_desc,
    hri.i_current_price,
    ts.combined_sales,
    ts.combined_profit,
    CASE 
        WHEN ts.combined_profit IS NULL THEN 'No Profit'
        WHEN ts.combined_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM HighReturnItems hri
JOIN TotalSales ts ON hri.sr_item_sk = ts.item_sk
WHERE ts.combined_sales > 100
ORDER BY ts.combined_profit DESC;
