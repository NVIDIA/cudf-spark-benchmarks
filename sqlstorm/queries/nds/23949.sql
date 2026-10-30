
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),

SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_paid_inc_tax) AS total_net_paid
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),

ReturnAnalysis AS (
    SELECT 
        CR.sr_item_sk,
        COALESCE(SD.total_sales, 0) AS total_sales,
        COALESCE(CR.total_returns, 0) AS total_returns,
        COALESCE(CR.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(CR.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(SD.total_sales, 0) = 0 THEN NULL
            ELSE (COALESCE(CR.total_returns, 0) * 100.0 / COALESCE(SD.total_sales, 1)) 
        END AS return_percentage
    FROM CustomerReturns CR
    FULL OUTER JOIN SalesData SD ON CR.sr_item_sk = SD.ws_item_sk
),

RankedReturns AS (
    SELECT 
        ra.*,
        RANK() OVER (PARTITION BY ra.sr_item_sk ORDER BY ra.return_percentage DESC) AS rank
    FROM ReturnAnalysis ra
)

SELECT 
    ra.sr_item_sk,
    ra.total_sales,
    ra.total_returns,
    ra.total_return_quantity,
    ra.total_return_amount,
    ra.return_percentage,
    CASE 
        WHEN ra.return_percentage IS NULL THEN 'No Sales'
        WHEN ra.return_percentage > 50 THEN 'High Returns'
        WHEN ra.return_percentage BETWEEN 20 AND 50 THEN 'Moderate Returns'
        ELSE 'Low Returns'
    END AS return_category
FROM RankedReturns ra
WHERE ra.rank = 1
AND ra.return_percentage IS NOT NULL
ORDER BY ra.return_percentage DESC
LIMIT 10;
