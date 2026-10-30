
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rnk
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk 
    HAVING 
        SUM(sr_return_amt) > (SELECT AVG(sr_return_amt) FROM store_returns)
),
InventoryInfo AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rk.ws_quantity, 0) AS total_sales_quantity,
    COALESCE(hvr.total_return_amt, 0) AS total_return_amount,
    COALESCE(ii.total_inventory, 0) AS total_inventory,
    (COALESCE(rk.ws_net_paid, 0) - COALESCE(hvr.total_return_amt, 0)) AS net_profit,
    CASE 
        WHEN COALESCE(rk.ws_net_paid, 0) IS NULL THEN 'No Sales'
        WHEN COALESCE(hvr.total_return_amt, 0) > 0 THEN 'Returns'
        ELSE 'Active'
    END AS sales_status
FROM 
    item i
LEFT JOIN 
    (SELECT * FROM RankedSales WHERE rnk = 1) rk ON i.i_item_sk = rk.ws_item_sk
LEFT JOIN 
    HighValueReturns hvr ON i.i_item_sk = hvr.sr_item_sk
LEFT JOIN 
    InventoryInfo ii ON i.i_item_sk = ii.inv_item_sk
WHERE 
    i.i_current_price > 20.00
ORDER BY 
    net_profit DESC
LIMIT 100;
