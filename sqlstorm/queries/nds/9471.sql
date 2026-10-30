
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk
), 
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        sd.s_store_name,
        sd.s_city,
        sd.s_state
    FROM
        item i
    JOIN store sd ON i.i_item_sk = sd.s_store_sk
)
SELECT
    id.i_product_name,
    id.i_brand,
    id.i_category,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    CONCAT(id.s_city, ', ', id.s_state) AS store_location
FROM
    sales_summary ss
JOIN item_details id ON ss.ws_item_sk = id.i_item_sk
ORDER BY total_sales DESC
LIMIT 10;
