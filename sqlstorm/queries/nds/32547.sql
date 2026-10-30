WITH  sales_summary AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) as total_quantity,
        SUM(ws.ws_ext_sales_price) as total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY SUM(ws.ws_quantity) DESC) as item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2001)
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_order_number, 
        ss.ws_item_sk, 
        ss.total_quantity, 
        ss.total_sales
    FROM 
        sales_summary ss
    WHERE 
        ss.item_rank = 1
)
SELECT 
    t.ws_order_number,
    COUNT(DISTINCT t.ws_item_sk) as items_count,
    SUM(t.total_sales) as total_sales_amount,
    AVG(t.total_quantity) as avg_quantity_per_item,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS top_products
FROM 
    top_sales t
JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
GROUP BY 
    t.ws_order_number
ORDER BY 
    total_sales_amount DESC
LIMIT 10;