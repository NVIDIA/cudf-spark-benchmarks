
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_item_sk
),
ItemData AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_category
    FROM 
        item
)
SELECT 
    id.i_product_name,
    SUM(sd.total_sales_price) AS total_revenue,
    SUM(sd.total_quantity) AS total_units_sold
FROM 
    SalesData sd
JOIN 
    ItemData id ON sd.ws_item_sk = id.i_item_sk
GROUP BY 
    id.i_product_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
