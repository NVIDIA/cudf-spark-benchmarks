
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_customer_sk, 
        sr_return_quantity,
        CASE 
            WHEN sr_return_quantity IS NULL THEN 'Unknown Return'
            WHEN sr_return_quantity = 0 THEN 'No Return'
            ELSE 'Returned'
        END AS return_status
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
SalesDetails AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        inv_quantity_on_hand,
        CASE 
            WHEN inv_quantity_on_hand < 10 THEN 'Low Stock'
            WHEN inv_quantity_on_hand BETWEEN 10 AND 50 THEN 'Moderate Stock'
            ELSE 'Sufficient Stock'
        END AS stock_level
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
),
FinalReport AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(cr.sr_return_quantity, 0) AS return_quantity,
        COALESCE(sd.total_quantity_sold, 0) AS total_sold,
        COALESCE(sd.total_net_profit, 0) AS total_profit,
        inv.inv_quantity_on_hand,
        inv.stock_level
    FROM 
        item i
    LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
    LEFT JOIN SalesDetails sd ON i.i_item_sk = sd.ws_item_sk
    JOIN InventoryStatus inv ON i.i_item_sk = inv.inv_item_sk
)
SELECT 
    *,
    CASE 
        WHEN return_quantity > total_sold * 0.5 THEN 'High Return Rate'
        WHEN total_sold = 0 THEN 'No Sales Recorded'
        ELSE 'Normal Return Rate'
    END AS return_rate_category
FROM 
    FinalReport
WHERE 
    (return_quantity IS NOT NULL OR total_sold > 0)
ORDER BY 
    return_rate_category DESC, total_profit DESC
LIMIT 100;
