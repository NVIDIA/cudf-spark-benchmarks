
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
inventory_data AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    i.total_inventory,
    (s.total_sales / NULLIF(s.total_quantity, 0)) AS avg_price_per_unit,
    (i.total_inventory - s.total_quantity) AS remaining_inventory
FROM 
    sales_data s
JOIN 
    inventory_data i ON s.ws_item_sk = i.inv_item_sk
WHERE 
    (i.total_inventory - s.total_quantity) > 0
ORDER BY 
    s.total_quantity DESC
LIMIT 100;
