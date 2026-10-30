
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        s.s_store_name,
        SUM(ss.ss_sales_price) AS TotalSales,
        COUNT(DISTINCT ss.ss_ticket_number) AS TransactionCount,
        AVG(ss.ss_sales_price) AS AvgSalesPrice
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, s.s_store_name
),
RankedSales AS (
    SELECT 
        d_year, 
        s_store_name, 
        TotalSales, 
        TransactionCount, 
        AvgSalesPrice,
        RANK() OVER (PARTITION BY d_year ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        SalesSummary
)
SELECT 
    d_year, 
    s_store_name, 
    TotalSales, 
    TransactionCount, 
    AvgSalesPrice
FROM 
    RankedSales
WHERE 
    SalesRank <= 5
ORDER BY 
    d_year, TotalSales DESC;
