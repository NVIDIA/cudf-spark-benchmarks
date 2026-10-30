
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk AS sold_date,
        ws_item_sk AS item,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        item,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    i.i_brand,
    i.i_category,
    s.total_quantity,
    s.total_sales,
    s.total_orders,
    d.d_date AS sales_date
FROM 
    sales_data s
JOIN 
    top_items ti ON s.item = ti.item
JOIN 
    item i ON s.item = i.i_item_sk
JOIN 
    date_dim d ON s.sold_date = d.d_date_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    s.total_sales DESC, 
    i.i_item_id;
