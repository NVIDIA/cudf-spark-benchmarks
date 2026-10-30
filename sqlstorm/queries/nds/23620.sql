
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY ws.ws_net_profit DESC) AS rn,
        ws.ws_net_profit,
        ws.ws_quantity,
        CASE 
            WHEN ws.ws_net_profit IS NULL THEN 'No Profit'
            WHEN ws.ws_net_profit > 100 THEN 'High Profit'
            ELSE 'Low Profit'
        END AS Profit_Category
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2) 
        AND ws.ws_ship_date_sk IS NOT NULL
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock,
        CASE 
            WHEN SUM(inv.inv_quantity_on_hand) < 50 THEN 'Low Stock'
            WHEN SUM(inv.inv_quantity_on_hand) BETWEEN 50 AND 200 THEN 'Moderate Stock'
            ELSE 'High Stock'
        END AS Stock_Status
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
CustomerReturns AS (
    SELECT 
        COUNT(*) AS total_returns,
        sr_item_sk 
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
)
SELECT 
    rs.ws_order_number,
    rs.ws_item_sk,
    rc.total_stock,
    rc.Stock_Status,
    cr.total_returns,
    rs.Profit_Category
FROM 
    RankedSales rs
LEFT JOIN 
    InventoryCheck rc ON rs.ws_item_sk = rc.inv_item_sk
LEFT JOIN 
    CustomerReturns cr ON rs.ws_item_sk = cr.sr_item_sk
WHERE 
    rs.rn = 1 
    AND (rc.Stock_Status = 'Low Stock' OR cr.total_returns > 10)
ORDER BY 
    rs.ws_order_number, 
    rs.ws_item_sk;
