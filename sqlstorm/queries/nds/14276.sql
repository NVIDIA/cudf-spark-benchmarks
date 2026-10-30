WITH SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459000 AND 2459007  
    GROUP BY 
        ws_item_sk
),
InventoryData AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    WHERE 
        inv_date_sk = 2459000  
    GROUP BY 
        inv_item_sk
)
SELECT 
    sd.ws_item_sk, 
    sd.total_quantity, 
    sd.total_sales, 
    id.total_inventory
FROM 
    SalesData sd
JOIN 
    InventoryData id ON sd.ws_item_sk = id.inv_item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 10;