WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546  
),
HighValueSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price) AS TotalSales,
        COUNT(rs.ws_order_number) AS OrderCount
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 10
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS TotalReturns,
        COUNT(sr.sr_ticket_number) AS ReturnsCount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        coalesce(hv.TotalSales, 0) AS TotalSales,
        coalesce(cr.TotalReturns, 0) AS TotalReturns,
        (coalesce(hv.TotalSales, 0) - coalesce(cr.TotalReturns, 0)) AS NetRevenue
    FROM 
        customer c
    LEFT JOIN 
        HighValueSales hv ON c.c_customer_sk = hv.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    fr.c_customer_id,
    fr.TotalSales,
    fr.TotalReturns,
    fr.NetRevenue,
    CASE 
        WHEN fr.NetRevenue > 1000 THEN 'High Value Customer'
        WHEN fr.NetRevenue BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS CustomerTier
FROM 
    FinalReport fr
ORDER BY 
    fr.NetRevenue DESC;