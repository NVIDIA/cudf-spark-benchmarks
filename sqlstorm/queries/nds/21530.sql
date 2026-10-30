
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
ItemReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
HighValueReturns AS (
    SELECT 
        ir.wr_item_sk,
        ir.total_returned,
        ir.return_count
    FROM 
        ItemReturns ir
    WHERE 
        ir.total_returned > (SELECT AVG(total_returned) FROM ItemReturns)
),
SalesAnalysis AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        COALESCE(hvr.total_returned, 0) AS total_returned,
        COALESCE(hvr.return_count, 0) AS return_count,
        rs.PriceRank
    FROM 
        RankedSales rs
    LEFT JOIN 
        HighValueReturns hvr ON rs.ws_item_sk = hvr.wr_item_sk
)
SELECT 
    ia.i_item_id,
    sa.ws_sales_price,
    sa.total_returned,
    sa.return_count,
    CASE 
        WHEN sa.return_count > 0 THEN 'Returned' 
        ELSE 'Not Returned' 
    END AS Return_Status,
    CASE 
        WHEN sa.ws_sales_price IS NOT NULL AND sa.total_returned > 0 THEN 
            ROUND(sa.ws_sales_price - (sa.ws_sales_price * 0.1), 2)
        ELSE sa.ws_sales_price 
    END AS Adjusted_Sales_Price
FROM 
    SalesAnalysis sa
JOIN 
    item ia ON sa.ws_item_sk = ia.i_item_sk
WHERE 
    sa.PriceRank = 1 
    AND ia.i_current_price IS NOT NULL
ORDER BY 
    Adjusted_Sales_Price DESC,
    Return_Status ASC
LIMIT 100;
