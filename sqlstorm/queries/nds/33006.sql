
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000 AND 2000
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 1000 AND 2000
    GROUP BY wr_item_sk
),
ItemStats AS (
    SELECT 
        i_item_sk,
        i_product_name,
        COALESCE(sd.ws_quantity, 0) AS total_sold,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        (COALESCE(sd.ws_quantity, 0) - COALESCE(cr.total_returned, 0)) AS net_sales,
        (CASE 
            WHEN COALESCE(sd.ws_quantity, 0) = 0 THEN NULL
            ELSE (COALESCE(cr.total_returned, 0) * 100.0 / COALESCE(sd.ws_quantity, 0))
        END) AS return_percentage
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
),
FinalReport AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY net_sales DESC) AS rank,
        item_stats.i_item_sk,
        item_stats.i_product_name,
        item_stats.total_sold,
        item_stats.total_returned,
        item_stats.total_return_amount,
        item_stats.net_sales,
        item_stats.return_percentage
    FROM ItemStats item_stats
    WHERE item_stats.net_sales > 0
)
SELECT 
    f.rank,
    f.i_item_sk,
    f.i_product_name,
    f.total_sold,
    f.total_returned,
    f.total_return_amount,
    f.net_sales,
    f.return_percentage
FROM FinalReport f
WHERE f.return_percentage IS NOT NULL
ORDER BY f.rank
LIMIT 10;
