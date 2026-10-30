
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
HighReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
),
TopSellingItems AS (
    SELECT 
        rss.ws_item_sk,
        SUM(rss.ws_quantity) AS total_quantity_sold,
        MAX(rss.ws_sales_price) AS max_price,
        MIN(rss.ws_sales_price) AS min_price
    FROM RankedSales rss
    WHERE rss.rank <= 5
    GROUP BY rss.ws_item_sk
),
FinalReport AS (
    SELECT 
        tsi.ws_item_sk,
        tsi.total_quantity_sold,
        tsi.max_price,
        tsi.min_price,
        COALESCE(hr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(hr.total_returned_amount, 0) AS total_returned_amount,
        (tsi.total_quantity_sold - COALESCE(hr.total_returned_quantity, 0)) AS net_sales,
        CASE 
            WHEN (tsi.total_quantity_sold - COALESCE(hr.total_returned_quantity, 0)) < 0 THEN 'Negative'
            WHEN (tsi.total_quantity_sold - COALESCE(hr.total_returned_quantity, 0)) = 0 THEN 'Neutral'
            ELSE 'Positive' 
        END AS sales_status
    FROM TopSellingItems tsi
    LEFT JOIN HighReturns hr ON tsi.ws_item_sk = hr.cr_item_sk
)
SELECT 
    fs.ws_item_sk,
    fs.total_quantity_sold,
    fs.max_price,
    fs.min_price,
    fs.total_returned_quantity,
    fs.total_returned_amount,
    fs.net_sales,
    fs.sales_status,
    CASE 
        WHEN fs.sales_status = 'Negative' AND fs.total_quantity_sold = 0 THEN 'All Returns'
        WHEN fs.total_returned_quantity = 0 THEN 'No Returns'
        ELSE 'Some Returns' 
    END AS return_analysis
FROM FinalReport fs
ORDER BY fs.ws_item_sk
