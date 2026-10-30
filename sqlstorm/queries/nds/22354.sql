
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
        AND ws_quantity > 0
),
TopItems AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_sold_date_sk) AS sales_days
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
    GROUP BY 
        ws_item_sk
),
StoreSalesInfo AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS store_quantity,
        AVG(ss_net_profit) AS avg_store_profit
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
InventoryLevels AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
SalesAndInventory AS (
    SELECT 
        T.ws_item_sk,
        COALESCE(T.total_quantity, 0) AS total_web_quantity,
        COALESCE(S.store_quantity, 0) AS total_store_quantity,
        COALESCE(I.total_inventory, 0) AS total_inventory,
        I.total_inventory - (COALESCE(T.total_quantity, 0) + COALESCE(S.store_quantity, 0)) AS inventory_diff
    FROM 
        TopItems T
    FULL OUTER JOIN 
        StoreSalesInfo S ON T.ws_item_sk = S.ss_item_sk
    FULL OUTER JOIN 
        InventoryLevels I ON T.ws_item_sk = I.inv_item_sk
)
SELECT 
    S.ws_item_sk,
    S.total_web_quantity,
    S.total_store_quantity,
    S.total_inventory,
    CASE 
        WHEN S.inventory_diff < 0 THEN 'Out of Stock' 
        WHEN S.inventory_diff = 0 THEN 'Just Enough' 
        ELSE 'In Stock' 
    END AS stock_status,
    DENSE_RANK() OVER (ORDER BY COALESCE(S.total_web_quantity, 0) + COALESCE(S.total_store_quantity, 0) DESC) AS overall_ranking
FROM 
    SalesAndInventory S
WHERE 
    (S.total_web_quantity IS NOT NULL OR S.total_store_quantity IS NOT NULL)
    AND (S.total_inventory IS NOT NULL OR S.total_inventory = 0)
ORDER BY 
    overall_ranking, S.ws_item_sk
LIMIT 20;
