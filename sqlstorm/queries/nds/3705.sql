
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS TotalReturned,
        SUM(wr.wr_return_amt) AS TotalReturnAmount
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returning_customer_sk IS NOT NULL
    GROUP BY 
        wr.wr_item_sk
),
InventoryData AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS TotalInventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    COUNT(DISTINCT r.ws_order_number) AS TotalOrders,
    COALESCE(SUM(r.ws_quantity), 0) AS TotalQuantitySold,
    COALESCE(SUM(r.ws_ext_sales_price), 0) AS TotalSales,
    COALESCE(c.TotalReturned, 0) AS TotalReturns,
    COALESCE(c.TotalReturnAmount, 0) AS TotalReturnAmount,
    COALESCE(inv.TotalInventory, 0) AS TotalInventory,
    CASE 
        WHEN COALESCE(SUM(r.ws_ext_sales_price), 0) > 10000 THEN 'High Sales'
        WHEN COALESCE(SUM(r.ws_ext_sales_price), 0) BETWEEN 5000 AND 10000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS SalesCategory
FROM 
    RankedSales r
LEFT JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN 
    CustomerReturns c ON i.i_item_sk = c.wr_item_sk
LEFT JOIN 
    InventoryData inv ON i.i_item_sk = inv.inv_item_sk
GROUP BY 
    i.i_item_id, c.TotalReturned, c.TotalReturnAmount, inv.TotalInventory
ORDER BY 
    TotalSales DESC;
