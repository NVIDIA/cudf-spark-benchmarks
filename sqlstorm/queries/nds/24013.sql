WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
        AND ws.ws_net_profit IS NOT NULL
),
TopItems AS (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk
),
ItemInventory AS (
    SELECT 
        i.i_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
),
SalesWithInventory AS (
    SELECT 
        ti.ws_item_sk, 
        ti.total_profit, 
        ii.total_inventory,
        CASE 
            WHEN ii.total_inventory IS NULL THEN 0
            WHEN ti.total_profit = 0 THEN NULL 
            ELSE ti.total_profit / ii.total_inventory 
        END AS profit_per_unit 
    FROM 
        TopItems ti
    LEFT JOIN 
        ItemInventory ii ON ti.ws_item_sk = ii.i_item_sk
)
SELECT 
    item.i_item_id, 
    item.i_item_desc, 
    sw.total_profit, 
    sw.total_inventory, 
    sw.profit_per_unit
FROM 
    SalesWithInventory sw
JOIN 
    item ON sw.ws_item_sk = item.i_item_sk
WHERE 
    (sw.profit_per_unit > 50 OR sw.profit_per_unit IS NULL)
    AND item.i_rec_start_date <= cast('2002-10-01' as date)
    AND (item.i_rec_end_date IS NULL OR item.i_rec_end_date > cast('2002-10-01' as date))
ORDER BY 
    sw.total_profit DESC
LIMIT 10;