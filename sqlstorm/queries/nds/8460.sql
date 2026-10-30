
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.ws_item_sk
),
top_sales AS (
    SELECT 
        sds.ws_item_sk,
        sds.total_quantity,
        sds.total_sales,
        sd.i_product_name
    FROM sales_data sds
    JOIN item sd ON sds.ws_item_sk = sd.i_item_sk
    ORDER BY sds.total_sales DESC
    LIMIT 10
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    ts.i_product_name,
    COALESCE(sr.sr_return_quantity, 0) AS total_returns,
    (ts.total_sales - COALESCE(sr.sr_return_quantity, 0) * sd.avg_sales_price) AS net_sales
FROM top_sales ts
LEFT JOIN (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS sr_return_quantity
    FROM catalog_returns
    GROUP BY cr_item_sk
) sr ON ts.ws_item_sk = sr.cr_item_sk
JOIN (
    SELECT 
        ws.ws_item_sk,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
) sd ON ts.ws_item_sk = sd.ws_item_sk
ORDER BY ts.total_sales DESC;
