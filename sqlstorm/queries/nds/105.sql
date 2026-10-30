
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS TotalQuantity
    FROM 
        web_sales AS ws
    INNER JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturns,
        COUNT(DISTINCT sr_ticket_number) AS ReturnCount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    it.i_item_id,
    COALESCE(rs.PriceRank, 0) AS SalesRank,
    COALESCE(rs.TotalQuantity, 0) AS TotalSold,
    COALESCE(cr.TotalReturns, 0) AS TotalReturned,
    CASE 
        WHEN COALESCE(cr.TotalReturns, 0) > 0 THEN 
            (COALESCE(cr.TotalReturns, 0) / NULLIF(rs.TotalQuantity, 0)) * 100
        ELSE 
            0
    END AS ReturnRate,
    it.i_color,
    it.i_brand
FROM 
    item it
LEFT JOIN 
    RankedSales rs ON it.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON it.i_item_sk = cr.sr_item_sk
WHERE 
    it.i_size IS NOT NULL
    AND (it.i_color NOT LIKE '%red%' OR it.i_brand = 'BrandA')
ORDER BY 
    ReturnRate DESC, 
    TotalSold DESC
LIMIT 10;
