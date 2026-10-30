
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL 
        AND ws.ws_ext_sales_price > 0
), 
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL 
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
), 
AggregateReturns AS (
    SELECT 
        cr.sr_item_sk, 
        SUM(cr.total_returned) AS total_returned_quantity
    FROM 
        CustomerReturns cr
    JOIN 
        RankedSales rs ON cr.sr_item_sk = rs.ws_item_sk
    WHERE 
        rs.sales_rank = 1
    GROUP BY 
        cr.sr_item_sk
), 
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk, 
        inv.inv_quantity_on_hand, 
        COALESCE(a.total_returned_quantity, 0) AS total_returned
    FROM 
        inventory inv
    LEFT JOIN 
        AggregateReturns a ON inv.inv_item_sk = a.sr_item_sk
)

SELECT 
    i.inv_item_sk, 
    i.inv_quantity_on_hand, 
    i.inv_quantity_on_hand - i.total_returned AS effective_inventory,
    CASE 
        WHEN i.inv_quantity_on_hand IS NOT NULL THEN 'Available'
        ELSE 'Out of Stock'
    END AS availability_status,
    CONCAT('Item ', i.inv_item_sk, ' has ', i.inv_quantity_on_hand, ' units available, with ', i.total_returned, ' returned items.') AS inventory_summary
FROM 
    InventoryCheck i
WHERE 
    i.inv_quantity_on_hand < (SELECT AVG(inv_quantity_on_hand) FROM inventory) + (SELECT COUNT(DISTINCT ws_item_sk) FROM web_sales)
ORDER BY 
    effective_inventory DESC
LIMIT 10;
