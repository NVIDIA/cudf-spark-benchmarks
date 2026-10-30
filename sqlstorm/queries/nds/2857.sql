
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_item_sk = ws.ws_item_sk)
),
TopSales AS (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS TotalSales
    FROM
        RankedSales rs
    WHERE
        rs.SalesRank <= 5
    GROUP BY
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS TotalReturns
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
)
SELECT
    i.i_item_id,
    COALESCE(ts.TotalSales, 0) AS TotalSales,
    COALESCE(cr.TotalReturns, 0) AS TotalReturns,
    (COALESCE(ts.TotalSales, 0) - COALESCE(cr.TotalReturns, 0)) AS NetSales
FROM
    item i
LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE
    (COALESCE(ts.TotalSales, 0) - COALESCE(cr.TotalReturns, 0) > 100 OR i.i_color IS NULL)
ORDER BY
    NetSales DESC
LIMIT 10;
