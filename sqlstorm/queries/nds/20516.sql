
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS TotalQuantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2022 
                                  AND d.d_moy IN (SELECT DISTINCT d_moy FROM date_dim WHERE d_year = 2021))
),
CustomerReturns AS (
    SELECT 
        cr.wr_item_sk,
        COUNT(DISTINCT cr.wr_order_number) AS ReturnCount,
        SUM(cr.wr_return_amt) AS TotalReturnAmt
    FROM 
        web_returns cr
    GROUP BY 
        cr.wr_item_sk
),
FilteredSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_quantity,
        cs.ReturnCount,
        cs.TotalReturnAmt,
        COALESCE(rs.ws_sales_price * rs.ws_quantity - COALESCE(cs.TotalReturnAmt, 0), 0) AS NetSales
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cs ON rs.ws_item_sk = cs.wr_item_sk
    WHERE 
        (rs.TotalQuantity > 100 AND rs.SalesRank = 1) OR 
        (rs.SalesRank <= 3 AND cs.ReturnCount IS NULL)
)
SELECT 
    fs.ws_item_sk,
    MAX(fs.NetSales) AS MaxNetSales,
    SUM(CASE WHEN fs.ReturnCount > 0 THEN fs.NetSales ELSE 0 END) AS TotalReturnedNetSales,
    AVG(fs.ws_sales_price) AS AvgSalesPrice
FROM 
    FilteredSales fs
GROUP BY 
    fs.ws_item_sk
HAVING 
    AVG(fs.ws_sales_price) > (SELECT AVG(ws_sales_price) 
                               FROM web_sales 
                               WHERE ws_sold_date_sk = 
                                     (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022))
ORDER BY 
    MaxNetSales DESC
LIMIT 10;
