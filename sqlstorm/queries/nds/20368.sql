
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
),
RecentReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
    )
    GROUP BY sr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_sales_price,
        COALESCE(rr.total_returns, 0) AS total_returns,
        (rs.ws_quantity * rs.ws_sales_price) - COALESCE(rr.total_returns, 0) * rs.ws_sales_price AS net_sales_value
    FROM RankedSales rs
    LEFT JOIN RecentReturns rr ON rs.ws_item_sk = rr.sr_item_sk
    WHERE rs.sales_rank = 1
),
AggregatedSales AS (
    SELECT 
        COUNT(*) AS item_count,
        SUM(net_sales_value) AS total_net_sales_value,
        CASE 
            WHEN net_sales_value > 100 THEN 'high'
            WHEN net_sales_value BETWEEN 50 AND 100 THEN 'medium'
            ELSE 'low'
        END AS sales_category
    FROM SalesWithReturns
    WHERE net_sales_value > 0
    GROUP BY sales_category
)
SELECT 
    CASE
        WHEN item_count IS NULL THEN 'No sales data'
        ELSE CONCAT('Sales bracket: ', CASE 
            WHEN total_net_sales_value > 1000 THEN 'Above 1000'
            ELSE 'Below or equal to 1000'
        END)
    END AS sales_bracket,
    item_count,
    total_net_sales_value 
FROM AggregatedSales
ORDER BY item_count DESC
LIMIT 5;
