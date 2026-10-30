
WITH SalesData AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_quantity, 
        ws_net_profit, 
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450500
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk, 
        SUM(sd.ws_quantity) AS total_quantity_sold,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.rn <= 10
    GROUP BY 
        sd.ws_item_sk
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    tsi.ws_item_sk,
    tsi.total_quantity_sold,
    tsi.total_net_profit,
    COALESCE(ic.total_inventory, 0) AS total_inventory,
    CASE 
        WHEN ic.total_inventory IS NULL THEN 'Out of Stock'
        WHEN ic.total_inventory < tsi.total_quantity_sold THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    TopSellingItems tsi
LEFT JOIN 
    InventoryCheck ic ON tsi.ws_item_sk = ic.inv_item_sk
ORDER BY 
    tsi.total_net_profit DESC;
