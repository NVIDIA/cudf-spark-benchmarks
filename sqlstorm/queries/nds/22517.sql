
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(DISTINCT sr_ticket_number) DESC) AS rn
    FROM store_returns
    GROUP BY sr_item_sk
),
TopReturns AS (
    SELECT 
        rr.sr_item_sk,
        rr.return_count,
        rr.total_return_amt,
        i.i_item_desc,
        i.i_current_price
    FROM RankedReturns rr
    JOIN item i ON rr.sr_item_sk = i.i_item_sk
    WHERE rr.rn <= 10
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 20000 
    GROUP BY ws.ws_item_sk
),
ItemMetrics AS (
    SELECT 
        tr.sr_item_sk AS item_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt,
        COALESCE(sd.net_profit, 0) AS net_profit,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) = 0 THEN NULL
            WHEN COALESCE(tr.total_return_amt, 0) = 0 THEN 0
            ELSE (COALESCE(tr.total_return_amt, 0) / COALESCE(sd.total_sales, 0)) * 100 
        END AS return_percentage
    FROM TopReturns tr
    LEFT JOIN SalesData sd ON tr.sr_item_sk = sd.ws_item_sk
),
FinalOutput AS (
    SELECT 
        item_sk,
        total_sales,
        total_return_amt,
        net_profit,
        return_percentage,
        CASE 
            WHEN return_percentage IS NULL THEN 'No sales'
            WHEN return_percentage > 50 THEN 'High return rate'
            WHEN return_percentage BETWEEN 20 AND 50 THEN 'Moderate return rate'
            ELSE 'Low return rate'
        END AS return_category
    FROM ItemMetrics
)
SELECT 
    f.item_sk,
    f.total_sales,
    f.total_return_amt,
    f.net_profit,
    f.return_percentage,
    f.return_category,
    CASE 
        WHEN f.return_percentage IS NOT NULL THEN 'Valid Return Percentage'
        ELSE 'Uncertain Data'
    END AS return_status
FROM FinalOutput f
WHERE f.net_profit > (SELECT AVG(net_profit) FROM ItemMetrics)
ORDER BY f.total_sales DESC
LIMIT 50;
