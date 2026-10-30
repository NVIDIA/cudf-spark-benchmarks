
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_quantity) AS total_quantity, 
        SUM(rs.ws_ext_sales_price) AS total_sales
    FROM RankedSales rs
    WHERE rs.rank <= 3
    GROUP BY rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk > 2000
    GROUP BY wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(cr.total_returned, 0) AS total_returned,
    CASE 
        WHEN COALESCE(cr.return_count, 0) > 0 THEN 
            ROUND((COALESCE(cr.total_returned, 0) / NULLIF(ts.total_quantity, 0)) * 100, 2)
        ELSE 
            0 
    END AS return_rate
FROM TopSales ts
JOIN item i ON ts.ws_item_sk = i.i_item_sk
LEFT JOIN CustomerReturns cr ON ts.ws_item_sk = cr.wr_item_sk
WHERE ts.total_sales > (SELECT AVG(total_sales) FROM TopSales) 
ORDER BY return_rate DESC
LIMIT 10 OFFSET 5;
