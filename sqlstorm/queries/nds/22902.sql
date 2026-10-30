
WITH InventoryAnalysis AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY inv.inv_item_sk ORDER BY inv.inv_quantity_on_hand DESC) AS rank,
        CASE 
            WHEN inv.inv_quantity_on_hand IS NULL THEN 'Out of Stock'
            WHEN inv.inv_quantity_on_hand < 50 THEN 'Low Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM inventory inv
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales_price,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk 
),
ReturnData AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
),
JoinResults AS (
    SELECT 
        ia.inv_item_sk,
        ia.inv_quantity_on_hand,
        COALESCE(sd.total_sales_price, 0) AS total_sales_price,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN ia.stock_status = 'Out of Stock' AND COALESCE(sd.total_sales_price, 0) = 0 THEN 'Cannot Order'
            WHEN (COALESCE(rd.total_returns, 0) / NULLIF(sd.total_quantity, 0)) > 0.5 THEN 'High Return Rate'
            ELSE 'Normal'
        END AS business_status
    FROM InventoryAnalysis ia
    LEFT JOIN SalesData sd ON ia.inv_item_sk = sd.ws_item_sk
    LEFT JOIN ReturnData rd ON ia.inv_item_sk = rd.cr_item_sk
)
SELECT 
    jr.inv_item_sk,
    jr.inv_quantity_on_hand,
    jr.total_sales_price,
    jr.total_returns,
    jr.total_return_amount,
    jr.business_status
FROM JoinResults jr
WHERE 
    (jr.inv_quantity_on_hand < 100 OR jr.total_sales_price > 1000)
    AND (jr.business_status != 'Cannot Order' OR jr.total_returns > 0)
ORDER BY 
    jr.business_status ASC, 
    jr.total_sales_price DESC
LIMIT 100
OFFSET 0;
