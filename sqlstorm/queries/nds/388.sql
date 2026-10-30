
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
InventoryCheck AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_stock
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(rs.total_sales, 0) AS total_web_sales,
    COALESCE(ic.total_stock, 0) AS available_stock,
    (COALESCE(rs.total_sales, 0) / NULLIF(ic.total_stock, 0)) AS sales_to_stock_ratio
FROM 
    item i
LEFT JOIN 
    TotalSales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    InventoryCheck ic ON i.i_item_sk = ic.inv_item_sk
WHERE 
    (COALESCE(rs.total_sales, 0) > 500 OR ic.total_stock IS NULL)
    AND i.i_current_price BETWEEN 10.00 AND 100.00
ORDER BY 
    sales_to_stock_ratio DESC
LIMIT 10;
