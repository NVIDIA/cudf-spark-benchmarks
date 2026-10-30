
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS rank_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_month_seq IN (SELECT d_month_seq FROM date_dim WHERE d_year = 2023 AND d_dow IN (1, 5))
),
high_value_items AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_value
    FROM 
        ranked_sales rs
    WHERE 
        rs.rank_price = 1 AND rs.rank_quantity = 1
    GROUP BY 
        rs.ws_item_sk
),
customer_return_stats AS (
    SELECT 
        sr.sr_item_sk,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    hvi.total_value,
    COALESCE(crs.total_returns, 0) AS total_returns,
    COALESCE(crs.avg_return_amt, 0) AS avg_return_amt,
    crs.return_count
FROM 
    item i
LEFT JOIN 
    high_value_items hvi ON i.i_item_sk = hvi.ws_item_sk
LEFT JOIN 
    customer_return_stats crs ON i.i_item_sk = crs.sr_item_sk
WHERE 
    hvi.total_value > (SELECT AVG(total_value) FROM high_value_items)
    OR (crs.total_returns > (SELECT COALESCE(MAX(total_returns), 0) FROM customer_return_stats) * 0.5
    AND crs.avg_return_amt IS NOT NULL)
ORDER BY 
    i.i_item_id;
