
WITH sales_data AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM 
        catalog_sales cs
    INNER JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        cs.cs_item_sk
), inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    s.cs_item_sk,
    s.total_quantity,
    s.total_net_paid,
    i.total_inventory
FROM 
    sales_data s
LEFT JOIN 
    inventory_data i ON s.cs_item_sk = i.inv_item_sk
ORDER BY 
    s.total_net_paid DESC
LIMIT 100;
