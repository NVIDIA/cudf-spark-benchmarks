
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders,
        AVG(rs.ws_sales_price) AS average_price
    FROM RankedSales rs
    WHERE rs.price_rank <= 5
    GROUP BY rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
FinalReport AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales_value,
        ss.total_orders,
        ss.average_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (ss.total_sales_value - COALESCE(cr.total_returns, 0) * ss.average_price) AS net_sales
    FROM SalesSummary ss
    LEFT JOIN CustomerReturns cr ON ss.ws_item_sk = cr.wr_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_sales_value,
    f.total_orders,
    f.average_price,
    f.total_returns,
    f.net_sales,
    CASE 
        WHEN f.net_sales < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS sales_status
FROM FinalReport f
WHERE f.total_sales_value IS NOT NULL
ORDER BY f.net_sales DESC
LIMIT 10;
