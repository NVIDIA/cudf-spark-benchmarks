
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.total_quantity
    FROM RankedSales rs
    WHERE rs.rn = 1
),
ReturnedItems AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.total_quantity, 0) AS total_sold,
    COALESCE(ri.total_returns, 0) AS total_returns,
    (COALESCE(ts.total_quantity, 0) - COALESCE(ri.total_returns, 0)) AS net_sales
FROM item i
LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN ReturnedItems ri ON i.i_item_sk = ri.wr_item_sk
WHERE i.i_current_price > 50.00 
  AND (COALESCE(ts.total_quantity, 0) > 0 OR COALESCE(ri.total_returns, 0) > 0)
ORDER BY net_sales DESC
LIMIT 10;
