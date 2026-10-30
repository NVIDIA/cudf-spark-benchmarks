
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) as SalesRank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 1500
),
TopSales AS (
    SELECT
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_sales_price,
        rs.ws_ext_sales_price
    FROM RankedSales rs
    WHERE rs.SalesRank <= 10
),
AggregatedReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(cr.cr_order_number) AS return_count
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 1000 AND 1500
    GROUP BY cr.cr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.ws_quantity, 0) AS total_sold_quantity,
    COALESCE(ar.total_return_quantity, 0) AS total_returned_quantity,
    (COALESCE(ts.ws_ext_sales_price, 0) - COALESCE(ar.total_return_amount, 0)) AS net_sales,
    CASE
        WHEN COALESCE(ts.ws_quantity, 0) = 0 THEN NULL
        ELSE (COALESCE(ar.total_return_quantity, 0) * 1.0 / COALESCE(ts.ws_quantity, 0))
    END AS return_rate
FROM item i
LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN AggregatedReturns ar ON i.i_item_sk = ar.cr_item_sk
WHERE i.i_current_price > 100
ORDER BY net_sales DESC
LIMIT 50;
