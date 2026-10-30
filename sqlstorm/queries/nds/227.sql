
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_payment
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2400 AND 2500
    GROUP BY ws.ws_item_sk
),
BestSellingItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        ss.avg_payment,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SalesSummary ss
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned,
        SUM(sr.sr_return_amt) AS total_returned_amt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
FinalReport AS (
    SELECT 
        bsi.ws_item_sk,
        bsi.total_quantity,
        bsi.total_sales,
        bsi.order_count,
        bsi.avg_payment,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt
    FROM BestSellingItems bsi
    LEFT JOIN CustomerReturns cr ON bsi.ws_item_sk = cr.sr_item_sk
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_sales,
    fr.order_count,
    fr.avg_payment,
    fr.total_returned,
    fr.total_returned_amt,
    CASE 
        WHEN fr.total_sales > 10000 THEN 'High Performer'
        WHEN fr.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM FinalReport fr
WHERE fr.total_quantity > 50
ORDER BY fr.total_sales DESC;
