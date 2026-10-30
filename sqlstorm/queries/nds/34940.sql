
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
), 
StockCTE AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_stock
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    s.total_quantity,
    s.total_sales_price,
    COALESCE(st.total_stock, 0) AS total_stock_available,
    CASE 
        WHEN st.total_stock IS NULL THEN 'No stock available'
        WHEN st.total_stock < s.total_quantity THEN 'Stock running low'
        ELSE 'Stock sufficient'
    END AS stock_status
FROM 
    SalesCTE s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
LEFT JOIN 
    StockCTE st ON i.i_item_sk = st.inv_item_sk
WHERE 
    s.rn = 1 
    AND s.total_sales_price > 1000 
    AND (s.total_quantity IS NOT NULL AND s.total_sales_price IS NOT NULL)
ORDER BY 
    total_sales_price DESC
LIMIT 10;
