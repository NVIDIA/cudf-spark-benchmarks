
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS ranking
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
inventory_levels AS (
    SELECT 
        inv.inv_item_sk,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        il.total_quantity_on_hand,
        (ss.total_sales / NULLIF(il.total_quantity_on_hand, 0)) AS sales_per_inventory
    FROM 
        sales_summary ss
    LEFT JOIN 
        inventory_levels il ON ss.ws_item_sk = il.inv_item_sk
    WHERE 
        ss.ranking <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ti.total_quantity_on_hand,
    ti.sales_per_inventory,
    CASE 
        WHEN ti.sales_per_inventory IS NULL THEN 'No Inventory Available'
        WHEN ti.sales_per_inventory > 0 THEN 'Good Sales Performance'
        ELSE 'Low Sales Performance'
    END AS performance_status
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 10.00
ORDER BY 
    ti.total_sales DESC
LIMIT 100;
