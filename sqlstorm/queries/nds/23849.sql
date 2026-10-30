
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_customer_sk, 
        sr_return_quantity, 
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM store_returns
    WHERE sr_return_quantity > 0
),
AggregateReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(*) AS total_returns, 
        SUM(sr_return_quantity) AS total_quantity_returned,
        MAX(sr_returned_date_sk) AS last_return_date
    FROM RankedReturns
    WHERE rnk <= 5
    GROUP BY sr_item_sk
),
HighReturnItems AS (
    SELECT 
        ar.sr_item_sk, 
        ar.total_returns, 
        ar.total_quantity_returned, 
        i.i_item_desc
    FROM AggregateReturns ar
    JOIN item i ON ar.sr_item_sk = i.i_item_sk
    WHERE ar.total_returns > 10
),
SalesData AS (
    SELECT 
        i.i_item_sk,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_revenue
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
FinalReport AS (
    SELECT 
        hri.sr_item_sk, 
        hri.i_item_desc, 
        hri.total_returns, 
        hri.total_quantity_returned, 
        COALESCE(sd.total_sold, 0) AS total_sold,
        COALESCE(sd.total_revenue, 0) AS total_revenue,
        CASE 
            WHEN COALESCE(sd.total_sold, 0) = 0 THEN 'No Sales'
            ELSE 'Sold'
        END AS sales_status
    FROM HighReturnItems hri
    LEFT JOIN SalesData sd ON hri.sr_item_sk = sd.i_item_sk
)
SELECT 
    f.sr_item_sk, 
    f.i_item_desc, 
    f.total_returns, 
    f.total_quantity_returned, 
    f.total_sold,
    f.total_revenue,
    CASE 
        WHEN f.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM FinalReport f
ORDER BY f.total_quantity_returned DESC, f.total_revenue DESC;
