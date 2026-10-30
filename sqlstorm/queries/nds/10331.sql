
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws_item_sk
),
inventory_data AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    WHERE 
        inv_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        inv_item_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_sales,
    sd.total_revenue,
    id.total_inventory
FROM 
    sales_data sd
JOIN 
    inventory_data id ON sd.ws_item_sk = id.inv_item_sk
ORDER BY 
    sd.total_revenue DESC
LIMIT 100;
