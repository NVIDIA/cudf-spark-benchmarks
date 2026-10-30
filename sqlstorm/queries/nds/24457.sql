
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
HighValueItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
    WHERE sd.total_sales > (SELECT AVG(total_sales) FROM SalesData)
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
FinalSales AS (
    SELECT 
        hvi.ws_item_sk,
        hvi.total_quantity,
        hvi.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        CASE 
            WHEN cr.total_returns IS NOT NULL THEN hvi.total_sales - cr.total_returns
            ELSE hvi.total_sales
        END AS net_sales
    FROM HighValueItems hvi
    LEFT JOIN CustomerReturns cr ON hvi.ws_item_sk = cr.sr_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    CASE 
        WHEN f.net_sales IS NOT NULL AND f.total_sales > 0 THEN (f.net_sales / f.total_sales) * 100
        ELSE NULL
    END AS return_percentage
FROM FinalSales f
WHERE f.net_sales > (SELECT AVG(net_sales) FROM FinalSales)
ORDER BY return_percentage DESC, f.total_sales DESC
LIMIT 10;
