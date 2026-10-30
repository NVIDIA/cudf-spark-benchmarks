
WITH sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(i.i_current_price, 0) AS current_price,
        i.i_brand,
        i.i_category
    FROM item i
),
top_selling_items AS (
    SELECT
        ss.ws_ship_date_sk,
        ss.ws_item_sk,
        ss.total_sales,
        ss.total_orders,
        ss.total_quantity,
        it.i_product_name,
        it.current_price,
        it.i_brand,
        it.i_category
    FROM sales_summary ss
    JOIN item_details it ON ss.ws_item_sk = it.i_item_sk
    WHERE ss.sales_rank <= 5
)
SELECT 
    d.d_date AS sales_date,
    tsi.i_product_name,
    tsi.total_sales,
    tsi.total_orders,
    tsi.total_quantity,
    tsi.current_price,
    tsi.i_brand,
    tsi.i_category,
    CASE 
        WHEN tsi.total_sales > 1000 THEN 'High Sales'
        WHEN tsi.total_sales > 500 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM top_selling_items tsi
JOIN date_dim d ON tsi.ws_ship_date_sk = d.d_date_sk
WHERE d.d_year = 2023
ORDER BY d.d_date, tsi.total_sales DESC;
