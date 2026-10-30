
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS TotalSales,
        COUNT(DISTINCT rs.ws_order_number) AS OrderCount
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS TotalReturns,
        SUM(sr.sr_return_amt_inc_tax) AS TotalReturnAmount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
Comparison AS (
    SELECT 
        ts.ws_item_sk,
        ts.TotalSales,
        COALESCE(cr.TotalReturns, 0) AS TotalReturns,
        COALESCE(cr.TotalReturnAmount, 0) AS TotalReturnAmount,
        (ts.TotalSales - COALESCE(cr.TotalReturnAmount, 0)) AS NetSales
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ws_item_sk = cr.sr_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    cmp.ws_item_sk,
    cmp.TotalSales,
    cmp.TotalReturns,
    cmp.NetSales,
    CASE 
        WHEN cmp.NetSales < 0 THEN 'Negative Sales'
        WHEN cmp.NetSales BETWEEN 0 AND 100 THEN 'Low Sales'
        WHEN cmp.NetSales BETWEEN 101 AND 1000 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS SalesCategory
FROM 
    Comparison cmp
JOIN 
    customer c ON c.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer WHERE c_birth_year IS NOT NULL)
WHERE 
    cmp.NetSales IS NOT NULL
ORDER BY 
    cmp.NetSales DESC
LIMIT 10;
