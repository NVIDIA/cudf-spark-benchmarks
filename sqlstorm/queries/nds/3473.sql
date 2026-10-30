
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rank_return
    FROM store_returns
    GROUP BY sr_item_sk
),
HighReturnItems AS (
    SELECT 
        rr.sr_item_sk,
        i.i_item_desc,
        rr.total_returns,
        rr.total_return_amt
    FROM RankedReturns rr
    JOIN item i ON rr.sr_item_sk = i.i_item_sk
    WHERE rr.rank_return <= 10
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amt
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
FinalReport AS (
    SELECT 
        hri.sr_item_sk,
        hri.i_item_desc,
        hri.total_returns,
        hri.total_return_amt,
        COALESCE(sd.total_sold, 0) AS total_sold,
        COALESCE(sd.total_sales_amt, 0) AS total_sales_amt,
        CASE 
            WHEN COALESCE(sd.total_sold, 0) = 0 THEN NULL
            ELSE ROUND((hri.total_return_amt / sd.total_sales_amt) * 100, 2) 
        END AS return_percentage
    FROM HighReturnItems hri
    LEFT JOIN SalesData sd ON hri.sr_item_sk = sd.ws_item_sk
)
SELECT 
    fr.sr_item_sk,
    fr.i_item_desc,
    fr.total_returns,
    fr.total_return_amt,
    fr.total_sold,
    fr.total_sales_amt,
    fr.return_percentage
FROM FinalReport fr
WHERE fr.return_percentage IS NOT NULL
ORDER BY fr.return_percentage DESC
LIMIT 20;
