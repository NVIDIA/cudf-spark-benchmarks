
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL 
        AND ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_sales_price IS NOT NULL)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    WHERE 
        wr_return_amt > 0
    GROUP BY 
        wr_returning_customer_sk
),
ReturnVsSales AS (
    SELECT 
        cr.wr_returning_customer_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COALESCE(SUM(cr.total_returned), 0) AS total_returns,
        CASE
            WHEN COALESCE(SUM(ws.ws_ext_sales_price), 0) > 0 THEN 
                ROUND((COALESCE(SUM(cr.total_returned), 0) / SUM(ws.ws_ext_sales_price)) * 100, 2)
            ELSE 
                NULL
        END AS return_percentage
    FROM 
        web_sales ws
    LEFT JOIN 
        CustomerReturns cr ON ws.ws_ship_customer_sk = cr.wr_returning_customer_sk
    GROUP BY 
        cr.wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    r.total_sales,
    r.total_returns,
    r.return_percentage,
    CASE 
        WHEN r.return_percentage IS NULL THEN 'No Sales'
        WHEN r.return_percentage >= 25 THEN 'High Return Rate'
        WHEN r.return_percentage BETWEEN 10 AND 24 THEN 'Moderate Return Rate'
        ELSE 'Low Return Rate'
    END AS return_category
FROM 
    ReturnVsSales r
JOIN 
    customer c ON c.c_customer_sk = r.wr_returning_customer_sk
WHERE 
    r.return_percentage IS NOT NULL 
    OR r.total_sales > 5000
ORDER BY 
    r.return_percentage DESC NULLS LAST
LIMIT 5 OFFSET 10;
