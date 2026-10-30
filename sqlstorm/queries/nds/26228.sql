
WITH InventoryCounts AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity, 
        i.i_item_desc, 
        i.i_brand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY inv.inv_item_sk, i.i_item_desc, i.i_brand
),
TopItems AS (
    SELECT 
        ic.inv_item_sk, 
        ic.total_quantity, 
        ic.i_item_desc, 
        ic.i_brand,
        RANK() OVER (ORDER BY ic.total_quantity DESC) AS rank
    FROM InventoryCounts ic
)
SELECT 
    CONCAT(t.i_brand, ' - ', t.i_item_desc) AS item_summary, 
    t.total_quantity
FROM TopItems t
WHERE t.rank <= 10
ORDER BY t.total_quantity DESC;
