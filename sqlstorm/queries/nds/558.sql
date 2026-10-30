
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS TotalReturns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        sr.sr_item_sk
),
CombinedSales AS (
    SELECT 
        i.i_item_id,
        COALESCE(rs.ws_sales_price, 0) AS SalesPrice,
        COALESCE(cr.TotalReturns, 0) AS TotalReturns,
        (COALESCE(rs.ws_sales_price, 0) * COALESCE(cr.TotalReturns, 0)) AS TotalLoss
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
)
SELECT 
    cs.i_item_id,
    cs.SalesPrice,
    cs.TotalReturns,
    cs.TotalLoss,
    (cs.SalesPrice - cs.TotalLoss) AS NetValue,
    CASE 
        WHEN cs.SalesPrice > 100 THEN 'High'
        WHEN cs.SalesPrice BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low' 
    END AS PriceCategory
FROM 
    CombinedSales cs
WHERE 
    cs.TotalLoss > 0
ORDER BY 
    NetValue DESC
LIMIT 10;
