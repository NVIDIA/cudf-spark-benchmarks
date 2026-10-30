WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS ranking
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
      AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
),
total_returns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns
    GROUP BY wr_item_sk
),
top_items AS (
    SELECT
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        COALESCE(tr.total_return_quantity, 0) AS total_returned_qty,
        COALESCE(tr.total_return_amount, 0.00) AS total_returned_amt
    FROM ranked_sales r
    LEFT JOIN total_returns tr ON r.ws_item_sk = tr.wr_item_sk
    WHERE r.ranking <= 3  
)
SELECT
    ti.ws_item_sk,
    i.i_item_desc,
    ti.ws_order_number,
    ti.ws_sales_price,
    ti.total_returned_qty,
    ti.total_returned_amt,
    CASE 
        WHEN ti.total_returned_qty > 0 THEN (ti.total_returned_amt / NULLIF(ti.total_returned_qty, 0))
        ELSE 0
    END AS return_avg_value
FROM top_items ti
JOIN item i ON ti.ws_item_sk = i.i_item_sk
ORDER BY ti.ws_sales_price DESC
LIMIT 10;