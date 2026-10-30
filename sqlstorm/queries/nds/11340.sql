
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451417 AND 2451481
    GROUP BY 
        ws_item_sk
), 
InventoryData AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)

SELECT 
    sd.ws_item_sk,
    sd.total_sales,
    id.total_inventory,
    (sd.total_sales / NULLIF(id.total_inventory, 0)) AS sales_per_inventory
FROM 
    SalesData sd
JOIN 
    InventoryData id ON sd.ws_item_sk = id.inv_item_sk
ORDER BY 
    sales_per_inventory DESC
LIMIT 10;
