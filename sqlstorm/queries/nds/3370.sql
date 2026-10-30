
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
    GROUP BY ws.ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_quantity,
        sd.order_count
    FROM SalesData sd
    WHERE sd.sales_rank <= 10
),
TotalReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_sales,
        COALESCE(tr.total_returned, 0) AS total_returned,
        ts.total_quantity,
        ts.order_count,
        (ts.total_sales - COALESCE(tr.total_returned * (ts.total_sales / NULLIF(ts.total_quantity, 0)), 0)) AS net_sales,
        CASE 
            WHEN ts.total_sales > 10000 THEN 'High Performer'
            WHEN ts.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM TopSales ts
    LEFT JOIN TotalReturns tr ON ts.ws_item_sk = tr.wr_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_sales,
    f.total_returned,
    f.total_quantity,
    f.order_count,
    f.net_sales,
    f.performance_category
FROM FinalReport f
ORDER BY f.net_sales DESC, f.performance_category;
