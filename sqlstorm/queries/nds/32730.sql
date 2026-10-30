
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), TopSales AS (
    SELECT 
        ws_item_sk,
        total_sales
    FROM 
        SalesCTE
    WHERE 
        rank <= 5
), InventoryCheck AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ic.total_inventory, 0) AS total_inventory,
    CASE WHEN ic.total_inventory < 100 THEN 'Low Stock' ELSE 'Sufficient Stock' END AS stock_status
FROM 
    item i
LEFT JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    InventoryCheck ic ON i.i_item_sk = ic.inv_item_sk
WHERE 
    i.i_current_price >= 10.00 AND 
    i.i_current_price <= 100.00
ORDER BY 
    total_sales DESC, 
    i.i_product_name;
