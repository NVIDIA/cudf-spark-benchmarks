
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws_ship_mode_sk,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturns,
        AVG(sr_return_amt) AS AvgReturnAmt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(cr.TotalReturns, 0) AS TotalReturns,
        COALESCE(cr.AvgReturnAmt, 0) AS AvgReturnAmt
    FROM 
        item i
    LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    id.TotalReturns,
    id.AvgReturnAmt,
    rs.ws_ship_mode_sk,
    rs.SalesRank
FROM 
    ItemDetails id
JOIN 
    RankedSales rs ON id.i_item_sk = rs.ws_item_sk
WHERE 
    (id.TotalReturns < (SELECT AVG(TotalReturns) FROM CustomerReturns) OR id.AvgReturnAmt IS NULL)
    AND id.i_current_price > 10.00
ORDER BY 
    rs.SalesRank, id.i_item_sk;
