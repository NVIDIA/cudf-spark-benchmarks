
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_returned_date_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
RecentInventory AS (
    SELECT 
        inv_item_sk,
        inv_quantity_on_hand,
        COALESCE(LEAD(inv_quantity_on_hand) OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk), 0) AS next_quantity,
        inv_date_sk
    FROM 
        inventory
    WHERE 
        inv_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow IN (1, 7)) 
),
SalesWithReturns AS (
    SELECT 
        i.i_item_id,
        COALESCE(r.return_count, 0) AS return_count,
        COALESCE(s.total_quantity_sold, 0) AS units_sold,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        inv.inv_quantity_on_hand,
        inv.next_quantity
    FROM 
        item i
    LEFT JOIN 
        (SELECT sr_item_sk, COUNT(*) AS return_count FROM RankedReturns WHERE rn <= 5 GROUP BY sr_item_sk) r ON i.i_item_sk = r.sr_item_sk
    LEFT JOIN 
        ItemSales s ON i.i_item_sk = s.ws_item_sk
    FULL OUTER JOIN 
        RecentInventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE 
        (r.return_count IS NOT NULL OR s.total_quantity_sold IS NOT NULL OR inv.inv_quantity_on_hand IS NOT NULL)
)
SELECT 
    s.i_item_id,
    SUM(CASE WHEN units_sold > 0 THEN units_sold ELSE NULL END) AS total_units_sold,
    AVG(total_net_profit) AS avg_net_profit,
    MAX(inv_quantity_on_hand) AS max_current_inventory,
    MIN(next_quantity) AS min_next_inventory,
    COUNT(CASE WHEN return_count > 0 THEN 1 END) AS total_returned_items,
    CASE 
        WHEN MAX(inv_quantity_on_hand) IS NULL THEN 'No Inventory' 
        WHEN AVG(total_net_profit) < 0 THEN 'Loss Leader'
        ELSE 'Regular Item'
    END AS item_classification
FROM 
    SalesWithReturns s
GROUP BY 
    s.i_item_id
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_units_sold DESC, avg_net_profit DESC;
