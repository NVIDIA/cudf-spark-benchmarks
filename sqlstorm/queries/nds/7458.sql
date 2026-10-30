
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_product_name,
        i_current_price,
        i_category
    FROM 
        item
),
CategorySales AS (
    SELECT 
        id.i_item_sk,
        id.i_item_id,
        id.i_product_name,
        id.i_current_price,
        sd.total_quantity,
        sd.total_sales,
        CASE 
            WHEN id.i_category = 'Electronics' THEN 'High Tech'
            WHEN id.i_category IN ('Clothing', 'Footwear') THEN 'Fashion'
            ELSE 'Other'
        END AS category_type
    FROM 
        SalesData sd
    JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    cs.category_type,
    SUM(cs.total_sales) AS total_sales_by_category,
    AVG(cs.total_quantity) AS avg_quantity_sold,
    COUNT(DISTINCT cs.i_item_id) AS unique_items_sold
FROM 
    CategorySales cs
GROUP BY 
    cs.category_type
ORDER BY 
    total_sales_by_category DESC;
