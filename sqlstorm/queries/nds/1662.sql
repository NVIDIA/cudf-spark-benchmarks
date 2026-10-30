
WITH SalesStats AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 10.00
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SalesStats ss
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
FinalReport AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (ti.total_sales - COALESCE(cr.total_returns * i.i_current_price, 0)) AS net_sales
    FROM TopItems ti
    LEFT JOIN CustomerReturns cr ON ti.ws_item_sk = cr.cr_item_sk
    JOIN item i ON ti.ws_item_sk = i.i_item_sk
    WHERE ti.sales_rank <= 10
)
SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    CASE 
        WHEN f.net_sales > 0 THEN 'Profitable' 
        ELSE 'Non-Profitable' 
    END AS profitability_status,
    'Sales for Item ' || f.ws_item_sk AS sales_message
FROM FinalReport f
ORDER BY f.net_sales DESC;
