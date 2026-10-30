
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
)
, Summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS TotalInventory,
        MAX(RankedSales.ws_sales_price) AS MaxSalesPrice
    FROM 
        inventory inv
    LEFT JOIN 
        RankedSales ON inv.inv_item_sk = RankedSales.ws_item_sk AND RankedSales.PriceRank = 1
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    CASE 
        WHEN st.s_store_sk IS NOT NULL THEN 'In Store'
        ELSE 'Online'
    END AS SalesChannel,
    COALESCE(s.TotalInventory, 0) AS TotalInventory,
    s.MaxSalesPrice,
    CASE 
        WHEN s.MaxSalesPrice IS NOT NULL AND s.TotalInventory > 50 THEN 'Plentiful'
        WHEN s.MaxSalesPrice IS NULL AND s.TotalInventory <= 50 THEN 'Out of Stock'
        ELSE 'Limited Stock'
    END AS StockStatus
FROM 
    Summary s
FULL OUTER JOIN 
    store st ON s.inv_item_sk = st.s_store_sk
WHERE 
    (s.TotalInventory IS NOT NULL OR st.s_store_sk IS NOT NULL)
    AND (s.MaxSalesPrice IS NULL OR s.MaxSalesPrice > 20.00)
ORDER BY 
    SalesChannel, s.MaxSalesPrice DESC;
