
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_paid) AS avg_net_paid,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY 
        ws_item_sk
), 
item_details AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price,
        i_category
    FROM 
        item 
    WHERE 
        i_rec_start_date <= '2023-10-31' AND (i_rec_end_date IS NULL OR i_rec_end_date >= '2023-10-01')
), 
category_summary AS (
    SELECT 
        id.i_category AS category,
        SUM(ss.total_sales_price) AS total_sales,
        SUM(ss.total_quantity) AS total_items_sold,
        AVG(ss.avg_net_paid) AS average_net_paid,
        COUNT(ss.total_orders) AS total_orders
    FROM 
        sales_summary ss
    JOIN 
        item_details id ON ss.ws_item_sk = id.i_item_sk
    GROUP BY 
        id.i_category
)
SELECT 
    category,
    total_sales,
    total_items_sold,
    average_net_paid,
    total_orders
FROM 
    category_summary
ORDER BY 
    total_sales DESC
LIMIT 10;
