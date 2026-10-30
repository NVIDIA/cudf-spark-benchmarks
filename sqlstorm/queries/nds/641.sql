
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
TotalSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS TotalSalesAmount
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 3  
    GROUP BY 
        rs.ws_item_sk
),
StorePerformance AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS TotalNetPaid,
        COUNT(DISTINCT ss.ss_ticket_number) AS TotalTransactions
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        s.s_number_employees > 10
    GROUP BY 
        ss.ss_store_sk
),
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        COALESCE(ts.TotalSalesAmount, 0) AS TotalSales,
        COALESCE(sp.TotalNetPaid, 0) AS StoreNetPaid,
        (COALESCE(ts.TotalSalesAmount, 0) - COALESCE(sp.TotalNetPaid, 0)) AS SalesDifference
    FROM 
        TotalSales ts
    FULL OUTER JOIN 
        StorePerformance sp ON ts.ws_item_sk = sp.ss_store_sk
)
SELECT 
    fr.ws_item_sk,
    fr.TotalSales,
    fr.StoreNetPaid,
    fr.SalesDifference,
    CASE 
        WHEN fr.SalesDifference > 0 THEN 'Higher Sales'
        WHEN fr.SalesDifference < 0 THEN 'Lower Sales'
        ELSE 'Equal Sales'
    END AS SalesComparison
FROM 
    FinalReport fr
WHERE 
    fr.TotalSales > 1000 OR fr.StoreNetPaid > 1000
ORDER BY 
    fr.SalesDifference DESC;
