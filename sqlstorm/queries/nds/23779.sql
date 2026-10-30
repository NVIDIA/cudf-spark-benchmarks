
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
TopProfitItems AS (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rnk = 1
    GROUP BY 
        rs.ws_item_sk
    HAVING 
        SUM(rs.ws_net_profit) IS NOT NULL
),
InventoryInfo AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ti.ws_item_sk,
    COALESCE(ti.total_net_profit, 0) AS profit,
    COALESCE(ii.total_quantity, 0) AS quantity,
    CASE 
        WHEN COALESCE(ti.total_net_profit, 0) = 0 THEN 'No Profit'
        WHEN COALESCE(ii.total_quantity, 0) = 0 THEN 'Out of Stock'
        ELSE 'Available'
    END AS status
FROM 
    TopProfitItems ti
FULL OUTER JOIN 
    InventoryInfo ii ON ti.ws_item_sk = ii.inv_item_sk
WHERE 
    (ti.total_net_profit IS NULL OR ii.total_quantity IS NULL)
    AND (COALESCE(ti.total_net_profit, -1) > 0 OR COALESCE(ii.total_quantity, -1) > 0)
ORDER BY 
    profit DESC, quantity ASC;
