
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count
    FROM sales_summary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE ss.sales_rank <= 10
),
customer_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM store_returns
    GROUP BY sr_item_sk
),
final_summary AS (
    SELECT 
        ti.ws_item_sk,
        ti.i_item_desc,
        ti.total_quantity,
        ti.total_sales,
        COALESCE(cr.total_return_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_value, 0) AS total_returned_value,
        (ti.total_sales - COALESCE(cr.total_returned_value, 0)) AS net_sales
    FROM top_items ti
    LEFT JOIN customer_returns cr ON ti.ws_item_sk = cr.sr_item_sk
)
SELECT 
    fs.ws_item_sk, 
    fs.i_item_desc,
    fs.total_quantity,
    fs.total_sales,
    fs.total_returned_quantity,
    fs.total_returned_value,
    fs.net_sales,
    CASE 
        WHEN fs.net_sales < 0 THEN 'Loss'
        WHEN fs.net_sales = 0 THEN 'Break-even'
        ELSE 'Profit'
    END AS sales_status
FROM final_summary fs
ORDER BY fs.net_sales DESC;
