
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023
    )
),
total_returns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(tr.total_returned, 0) AS total_returned,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt
    FROM item i
    LEFT JOIN total_returns tr ON i.i_item_sk = tr.wr_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
    id.total_returned,
    id.total_return_amt,
    CASE 
        WHEN id.total_returned > 0 THEN
            ROUND((SUM(rs.ws_sales_price * rs.ws_quantity) / NULLIF(id.total_returned, 0)), 2)
        ELSE 0
    END AS sales_per_return,
    CASE 
        WHEN MAX(rs.price_rank) = 1 THEN 'Top Price'
        ELSE 'Regular Price'
    END AS price_category
FROM ranked_sales rs
JOIN item_details id ON rs.ws_item_sk = id.i_item_sk
GROUP BY 
    id.i_item_sk,
    id.i_item_desc,
    id.total_returned,
    id.total_return_amt
HAVING SUM(rs.ws_sales_price * rs.ws_quantity) > 1000
ORDER BY total_sales DESC;
