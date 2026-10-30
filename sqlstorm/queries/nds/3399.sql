
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
TotalReturns AS (
    SELECT 
        wr.wr_item_sk, 
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns wr 
    GROUP BY 
        wr.wr_item_sk
),
SalesSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_current_price AS current_price,
        COALESCE(tr.total_return_qty, 0) AS total_return_qty,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt
    FROM 
        item i
    LEFT JOIN TotalReturns tr ON i.i_item_sk = tr.wr_item_sk
)
SELECT 
    ss.i_item_sk,
    ss.current_price,
    ss.total_return_qty,
    ss.total_return_amt,
    ROUND(ss.current_price - (ss.total_return_amt / NULLIF(ss.total_return_qty, 0)), 2) AS adjusted_price
FROM 
    SalesSummary ss
JOIN 
    RankedSales rs ON ss.i_item_sk = rs.ws_item_sk AND rs.rn = 1
WHERE 
    ss.total_return_qty > 0 OR 
    (ss.total_return_qty = 0 AND ss.current_price > 20)
ORDER BY 
    adjusted_price DESC
LIMIT 10;
