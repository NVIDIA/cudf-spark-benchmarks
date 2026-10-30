
WITH CustomerReturns AS (
    SELECT 
        sr_cdemo_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk > 2000000 
    GROUP BY sr_cdemo_sk
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_sales_price) AS total_sales_amt
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
),
ReturnStats AS (
    SELECT 
        cdemo.cd_demo_sk,
        COALESCE(cr.total_returned_quantity, 0) AS return_quantity,
        COALESCE(cr.total_returned_amt, 0) AS return_amount,
        COALESCE(sd.total_sales_quantity, 0) AS sales_quantity,
        COALESCE(sd.total_sales_amt, 0) AS sales_amount,
        CASE 
            WHEN COALESCE(sd.total_sales_amt, 0) > 0 THEN 
                (COALESCE(cr.total_returned_amt, 0) / COALESCE(sd.total_sales_amt, 0)) * 100
            ELSE 0 
        END AS return_percentage
    FROM customer_demographics cdemo
    LEFT JOIN CustomerReturns cr ON cdemo.cd_demo_sk = cr.sr_cdemo_sk
    LEFT JOIN SalesData sd ON cdemo.cd_demo_sk = sd.ws_bill_cdemo_sk
),
RankedReturns AS (
    SELECT 
        return_stats.*,
        RANK() OVER (PARTITION BY return_quantity, return_amount ORDER BY return_percentage DESC) AS rank_return_stats
    FROM ReturnStats return_stats
)
SELECT 
    r.cd_demo_sk,
    r.return_quantity,
    r.return_amount,
    r.sales_quantity,
    r.sales_amount,
    r.return_percentage,
    CASE 
        WHEN r.return_percentage > 50 THEN 'High Return'
        WHEN r.return_percentage BETWEEN 20 AND 50 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category,
    (SELECT COUNT(*) FROM RankedReturns rr WHERE rr.rank_return_stats <= r.rank_return_stats) AS cumulative_rank
FROM RankedReturns r
WHERE r.return_amount IS NOT NULL 
AND r.sales_quantity > (
    SELECT AVG(total_sales_quantity) FROM SalesData
)
ORDER BY r.return_percentage DESC
LIMIT 10;

