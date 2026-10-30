
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS item_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_net_profit,
        sm.sm_type,
        i.i_product_name,
        COALESCE(i.i_current_price, 0) AS current_price
    FROM sales_summary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON i.i_class_id = sm.sm_ship_mode_sk
    WHERE ss.item_rank <= 10
),
customer_returns AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_sales,
    t.avg_net_profit,
    t.sm_type,
    t.i_product_name,
    t.current_price,
    COALESCE(cr.return_count, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amount,
    CASE
        WHEN t.current_price > 0 THEN (t.total_sales / t.total_quantity) - t.current_price
        ELSE NULL
    END AS price_difference
FROM top_sales t
LEFT JOIN customer_returns cr ON t.ws_item_sk = cr.sr_item_sk
ORDER BY t.total_sales DESC, t.total_quantity DESC;
