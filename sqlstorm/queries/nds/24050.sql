
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
), TotalReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
), SalesWithReturns AS (
    SELECT
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_quantity,
        COALESCE(tr.total_returned, 0) AS total_returned,
        CASE 
            WHEN rs.ws_quantity > COALESCE(tr.total_returned, 0) THEN rs.ws_quantity - COALESCE(tr.total_returned, 0)
            ELSE 0
        END AS net_sales_quantity
    FROM RankedSales rs
    LEFT JOIN TotalReturns tr ON rs.ws_item_sk = tr.cr_item_sk
)
SELECT
    ss.s_store_sk,
    COUNT(DISTINCT CASE WHEN s.net_sales_quantity > 0 THEN s.ws_order_number END) AS fulfilled_orders,
    AVG(s.ws_sales_price) AS average_sales_price,
    SUM(s.net_sales_quantity) AS total_net_sales,
    DENSE_RANK() OVER (ORDER BY SUM(s.net_sales_quantity) DESC) AS sales_rank
FROM SalesWithReturns s
INNER JOIN store ss ON s.ws_item_sk = ss.s_store_sk
WHERE s.net_sales_quantity IS NOT NULL
GROUP BY ss.s_store_sk
HAVING AVG(s.ws_sales_price) > (SELECT AVG(ws.ws_sales_price) FROM web_sales ws WHERE ws.ws_sales_price IS NOT NULL) * 0.9
  AND COUNT(DISTINCT s.ws_order_number) > 10
ORDER BY sales_rank
