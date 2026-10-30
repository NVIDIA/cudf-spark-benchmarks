
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
        AND ws.ws_quantity > 0
),
TopSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM RankedSales
    WHERE rank_sales = 1
    GROUP BY ws_item_sk
),
ItemInventory AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        DENSE_RANK() OVER (ORDER BY inv.inv_quantity_on_hand DESC) AS rank_inventory 
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = 1
)
SELECT 
    i.i_item_id,
    COALESCE(ts.total_quantity, 0) AS sold_quantity,
    COALESCE(ts.total_sales, 0) AS total_sales_value,
    COALESCE(ii.inv_quantity_on_hand, 0) AS quantity_on_hand,
    CASE 
        WHEN COALESCE(ts.total_quantity, 0) > 0 THEN 'High Demand'
        WHEN COALESCE(ii.inv_quantity_on_hand, 0) > 0 THEN 'Stock Available'
        ELSE 'Out of Stock' 
    END AS stock_status
FROM 
    item i
LEFT JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    ItemInventory ii ON i.i_item_sk = ii.inv_item_sk AND ii.rank_inventory = 1
WHERE 
    i.i_current_price IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_store_sk = ii.inv_item_sk 
        AND s.s_number_employees IS NULL
    )
ORDER BY 
    total_sales_value DESC, 
    sold_quantity ASC
LIMIT 50;
