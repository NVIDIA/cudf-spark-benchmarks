
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    id.i_brand,
    sd.total_quantity,
    sd.total_sales,
    sd.total_orders
FROM 
    ItemDetails id
JOIN 
    SalesData sd ON id.i_item_sk = sd.ws_item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
