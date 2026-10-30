
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0
),
AggregatedReturns AS (
    SELECT 
        cr.sr_item_sk,
        SUM(cr.sr_return_quantity) AS total_returned_qty,
        SUM(cr.sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(*) AS return_count
    FROM CustomerReturns cr
    WHERE cr.rn <= 5
    GROUP BY cr.sr_item_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_qty,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amt,
        COUNT(*) AS sale_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
FinalResults AS (
    SELECT 
        COALESCE(sd.ws_item_sk, ar.sr_item_sk) AS item_sk,
        COALESCE(sd.total_sold_qty, 0) AS total_sold_qty,
        COALESCE(ar.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(sd.total_sales_amt, 0) - COALESCE(ar.total_returned_amt, 0) AS net_sales_amt,
        sd.sale_count AS total_sales_count,
        ar.return_count AS total_return_count,
        CASE 
            WHEN COALESCE(ar.return_count, 0) > 0 THEN 'Returns Exist'
            ELSE 'No Returns'
        END AS return_status
    FROM SalesDetails sd
    FULL OUTER JOIN AggregatedReturns ar ON sd.ws_item_sk = ar.sr_item_sk
)
SELECT 
    item_sk,
    total_sold_qty,
    total_returned_qty,
    net_sales_amt,
    total_sales_count,
    total_return_count,
    return_status
FROM FinalResults
WHERE 
    (total_sold_qty - total_returned_qty) > 100 
    AND net_sales_amt > 1000
    AND return_status = 'Returns Exist'
ORDER BY total_sold_qty DESC, net_sales_amt DESC
LIMIT 10;
