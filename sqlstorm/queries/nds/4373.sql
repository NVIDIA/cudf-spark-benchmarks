
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS RankQuantities
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
), 
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS TotalQuantity,
        AVG(ws_sales_price) AS AveragePrice
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                             (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
SalesReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS TotalReturns,
        SUM(wr_return_amt) AS TotalReturnAmount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ss.TotalQuantity, 0) AS TotalSold,
    COALESCE(ss.AveragePrice, 0) AS AveragePrice,
    COALESCE(sr.TotalReturns, 0) AS TotalReturns,
    COALESCE(sr.TotalReturnAmount, 0) AS TotalReturnAmount,
    RANK() OVER (ORDER BY COALESCE(ss.TotalQuantity, 0) DESC) AS SalesRank
FROM 
    item i
LEFT JOIN 
    SalesSummary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    SalesReturns sr ON i.i_item_sk = sr.wr_item_sk
WHERE 
    i.i_current_price > 10.00 
    AND (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) > 100
ORDER BY 
    SalesRank
LIMIT 100;
