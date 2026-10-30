
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number) AS rn
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
total_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales_value
    FROM sales_data sd
    GROUP BY sd.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ts.total_quantity, 0) AS total_quantity,
        COALESCE(ts.total_sales_value, 0) AS total_sales_value
    FROM item i
    LEFT JOIN total_sales ts ON i.i_item_sk = ts.ws_item_sk
),
sales_stats AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        id.i_current_price,
        id.total_quantity,
        id.total_sales_value,
        CASE 
            WHEN id.total_quantity = 0 THEN 0 
            ELSE (id.total_sales_value / id.total_quantity) 
        END AS avg_sales_price
    FROM item_details id
),
top_selling_items AS (
    SELECT 
        s.i_item_sk,
        s.i_item_desc,
        s.total_quantity,
        s.avg_sales_price,
        RANK() OVER (ORDER BY s.total_quantity DESC) AS item_rank
    FROM sales_stats s
)
SELECT 
    tsi.i_item_sk,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.avg_sales_price
FROM top_selling_items tsi
WHERE tsi.item_rank <= 10
ORDER BY tsi.total_quantity DESC;
