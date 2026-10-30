
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_returns
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
DailySales AS (
    SELECT 
        dd.d_date,
        COALESCE(SUM(s.total_sales), 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (COALESCE(SUM(s.total_sales), 0) - COALESCE(r.total_returns, 0)) AS net_sales
    FROM date_dim dd
    LEFT JOIN SalesCTE s ON dd.d_date_sk = s.ws_sold_date_sk
    LEFT JOIN CustomerReturns r ON dd.d_date_sk = r.cr_returned_date_sk
    GROUP BY dd.d_date, r.total_returns
)
SELECT 
    d.d_date,
    d.total_sales,
    d.total_returns,
    d.net_sales,
    CASE 
        WHEN d.net_sales > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS sales_status
FROM DailySales d
ORDER BY d.d_date DESC
LIMIT 30;
