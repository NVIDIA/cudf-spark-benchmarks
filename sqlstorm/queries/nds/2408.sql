
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20000101 AND 20051231
), 
ItemInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
    HAVING SUM(inv.inv_quantity_on_hand) > 0
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity
    FROM SalesData sd
    WHERE sd.rn <= 10
    GROUP BY sd.ws_item_sk
    ORDER BY total_quantity DESC
    LIMIT 5
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    tsi.total_quantity,
    ii.total_inventory,
    (tsi.total_quantity - COALESCE(ii.total_inventory, 0)) AS inventory_difference,
    CASE 
        WHEN (tsi.total_quantity - COALESCE(ii.total_inventory, 0)) > 0 THEN 'Stock Required'
        WHEN (tsi.total_quantity - COALESCE(ii.total_inventory, 0)) = 0 THEN 'Perfectly Aligned'
        ELSE 'Overstock'
    END AS stock_status
FROM TopSellingItems tsi
JOIN item ti ON ti.i_item_sk = tsi.ws_item_sk
LEFT JOIN ItemInventory ii ON ii.inv_item_sk = tsi.ws_item_sk
ORDER BY tsi.total_quantity DESC;
