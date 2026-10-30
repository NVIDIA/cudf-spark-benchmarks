
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk
),
product_info AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        ii.i_brand
    FROM 
        item AS i
    JOIN 
        (SELECT DISTINCT i_item_sk, i_brand FROM item) AS ii ON i.i_item_sk = ii.i_item_sk
)
SELECT 
    p.i_product_name,
    p.i_category,
    p.i_brand,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_sales_price,
    ss.order_count
FROM 
    sales_summary AS ss
JOIN 
    product_info AS p ON ss.ws_item_sk = p.i_item_sk
WHERE 
    ss.total_quantity > 100
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
