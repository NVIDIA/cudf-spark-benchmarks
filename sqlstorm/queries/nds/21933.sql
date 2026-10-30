
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales 
    FROM web_sales
    WHERE ws_sales_price > 100
    GROUP BY ws_item_sk
),
RecentReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS returned_quantity,
        SUM(sr_return_amt) AS total_returned  
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
    GROUP BY sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        t.ws_item_sk, 
        t.total_quantity, 
        t.total_sales,
        COALESCE(r.returned_quantity, 0) AS returned_quantity,
        COALESCE(r.total_returned, 0) AS total_returned,
        (t.total_sales - COALESCE(r.total_returned, 0)) AS net_sales
    FROM TotalSales t
    LEFT JOIN RecentReturns r ON t.ws_item_sk = r.sr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    s.total_sales,
    s.returned_quantity,
    s.total_returned,
    s.net_sales,
    CASE 
        WHEN s.net_sales < 0 THEN 'Negative Profit'
        WHEN s.total_quantity = 0 THEN 'No Sales'
        ELSE 'Profit'
    END AS profit_status,
    d.d_day_name
FROM SalesAndReturns s
JOIN date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
WHERE d.d_year = 2023 
AND (SELECT COUNT(*) FROM RankedSales r WHERE r.ws_item_sk = s.ws_item_sk AND r.rn = 1) > 1
ORDER BY s.net_sales DESC
LIMIT 50;
