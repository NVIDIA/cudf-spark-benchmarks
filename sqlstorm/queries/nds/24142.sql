
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) 
                              FROM web_sales ws2 
                              WHERE ws2.ws_item_sk = ws.ws_item_sk
                              AND ws2.ws_sold_date_sk > 20220101)
),
ItemReturns AS (
    SELECT 
        ir.cr_item_sk, 
        SUM(ir.cr_return_quantity) AS TotalReturns
    FROM 
        catalog_returns ir
    WHERE 
        ir.cr_returned_date_sk BETWEEN 20220101 AND 20221231 
    GROUP BY 
        ir.cr_item_sk
),
ItemStats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(rs.ws_sales_price), 0) AS TotalSalesPrice,
        COALESCE(SUM(ir.TotalReturns), 0) AS TotalReturns,
        COALESCE(AVG(rs.ws_sales_price), 0) AS AvgSalesPrice,
        COUNT(DISTINCT ws.ws_order_number) AS SaleCount
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        ItemReturns ir ON i.i_item_sk = ir.cr_item_sk
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    it.i_item_sk,
    it.i_item_desc,
    it.TotalSalesPrice,
    it.TotalReturns,
    it.AvgSalesPrice,
    it.SaleCount,
    CASE 
        WHEN it.TotalSalesPrice > 1000 THEN 'High Value'
        WHEN it.TotalSalesPrice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS ValueCategory
FROM 
    ItemStats it
WHERE 
    (it.TotalReturns IS NULL OR it.TotalReturns < (SELECT AVG(TotalReturns) FROM ItemStats))
    AND it.AvgSalesPrice IS NOT NULL
ORDER BY 
    it.TotalSalesPrice DESC
LIMIT 10;
