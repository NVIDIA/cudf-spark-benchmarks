
WITH  recent_sales AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = (SELECT MAX(d_year) FROM date_dim))
), 
sales_summary AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name, 
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_sales,
        COUNT(ws_quantity) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS unique_order_count
    FROM item
    LEFT JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY item.i_item_id, item.i_product_name
), 
high_value_sales AS (
    SELECT 
        sales_summary.*, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM sales_summary
    WHERE total_sales > (SELECT AVG(total_sales) FROM sales_summary)
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    hvs.i_product_name,
    hvs.total_sales,
    hvs.total_orders,
    hvs.avg_sales_price,
    COALESCE(c.c_birth_year, 1900) AS birth_year,
    CASE 
        WHEN hvs.unique_order_count IS NULL THEN 'UNKNOWN' 
        ELSE CAST(hvs.unique_order_count AS STRING)
    END AS unique_order_count_display
FROM high_value_sales hvs
LEFT JOIN customer c ON hvs.total_orders = c.c_customer_sk
WHERE c.c_customer_sk IS NOT NULL
ORDER BY hvs.total_sales DESC
LIMIT 10;
