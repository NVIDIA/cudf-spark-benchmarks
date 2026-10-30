
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_item_sk IS NOT NULL)
), 
AggregatedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        SalesCTE
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
),
WarehouseInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
JoinCTE AS (
    SELECT 
        a.ws_item_sk,
        a.total_quantity,
        a.total_net_profit,
        b.total_quantity_on_hand,
        CASE WHEN b.total_quantity_on_hand IS NULL THEN 'No Inventory' ELSE 'In Stock' END AS inventory_status
    FROM 
        AggregatedSales a
    LEFT JOIN 
        WarehouseInventory b ON a.ws_item_sk = b.inv_item_sk
)
SELECT 
    j.ws_item_sk,
    j.total_quantity,
    j.total_net_profit,
    j.total_quantity_on_hand,
    j.inventory_status,
    ROW_NUMBER() OVER (ORDER BY j.total_net_profit DESC) AS ranking,
    (CASE 
        WHEN j.total_net_profit IS NULL THEN 'Profit Unknown' 
        WHEN j.total_net_profit < 0 THEN 'Net Loss' 
        ELSE 'Profitable' 
    END) AS profit_status
FROM 
    JoinCTE j
WHERE 
    j.total_net_profit IS NOT NULL 
AND 
    j.total_net_profit > 0 
OR 
    (j.total_net_profit IS NULL AND j.total_quantity_on_hand IS NOT NULL)
ORDER BY 
    ranking
LIMIT 50;
