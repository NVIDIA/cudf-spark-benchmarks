
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
), 
TotalReturned AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_item_sk
), 
SalesStatistics AS (
    SELECT 
        r.ws_item_sk,
        COALESCE(t.total_returns, 0) AS total_returns,
        COUNT(r.ws_item_sk) AS total_sales,
        AVG(r.ws_sales_price) AS avg_sales_price,
        MAX(r.ws_sales_price) AS max_sales_price,
        MIN(r.ws_sales_price) AS min_sales_price,
        DENSE_RANK() OVER (ORDER BY AVG(r.ws_sales_price) DESC) AS sales_rank
    FROM RankedSales r
    LEFT JOIN TotalReturned t ON r.ws_item_sk = t.cr_item_sk
    GROUP BY r.ws_item_sk, t.total_returns
)
SELECT 
    s.ws_item_sk,
    s.total_sales,
    s.total_returns,
    s.avg_sales_price,
    s.max_sales_price,
    s.min_sales_price,
    CASE 
        WHEN s.total_returns > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CASE 
        WHEN s.total_returns = 0 AND s.total_sales > 50 THEN 'High Performer'
        WHEN s.total_sales = 0 THEN 'No Sales'
        ELSE 'Average Performer'
    END AS performance_category
FROM SalesStatistics s
WHERE s.sales_rank <= 10
ORDER BY s.total_sales DESC, s.avg_sales_price DESC
LIMIT 20 OFFSET 0;
