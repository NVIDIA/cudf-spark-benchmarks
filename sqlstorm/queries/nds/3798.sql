
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS SalesRank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2455470 AND 2455500
),
AggregatedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS TotalReturns,
        SUM(cr_return_amount) AS TotalReturnAmount
    FROM catalog_returns
    WHERE cr_returned_date_sk >= 2455470
    GROUP BY cr_item_sk
),
ItemInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS TotalInventory
    FROM inventory
    WHERE inv_date_sk = 2455490
    GROUP BY inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(RS.ws_quantity, 0) AS QuantitySold,
    COALESCE(RS.ws_sales_price, 0) AS SalesPrice,
    COALESCE(AR.TotalReturns, 0) AS TotalReturns,
    COALESCE(AR.TotalReturnAmount, 0) AS TotalReturnAmount,
    II.TotalInventory,
    (COALESCE(RS.ws_sales_price, 0) - COALESCE(AR.TotalReturnAmount, 0) / NULLIF(AR.TotalReturns, 0)) AS AdjustedPrice,
    CASE 
        WHEN II.TotalInventory < 100 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS StockStatus
FROM item i
LEFT JOIN RankedSales RS ON i.i_item_sk = RS.ws_item_sk AND RS.SalesRank = 1
LEFT JOIN AggregatedReturns AR ON i.i_item_sk = AR.cr_item_sk
JOIN ItemInventory II ON i.i_item_sk = II.inv_item_sk
WHERE COALESCE(AR.TotalReturns, 0) > 5
ORDER BY AdjustedPrice DESC;
