
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS TotalWebSales,
        SUM(cs.cs_ext_sales_price) AS TotalCatalogSales,
        SUM(ss.ss_ext_sales_price) AS TotalStoreSales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
), SalesStats AS (
    SELECT 
        c.c_customer_id,
        TotalWebSales,
        TotalCatalogSales,
        TotalStoreSales,
        COALESCE(TotalWebSales, 0) + COALESCE(TotalCatalogSales, 0) + COALESCE(TotalStoreSales, 0) AS TotalSales,
        RANK() OVER (ORDER BY COALESCE(TotalWebSales, 0) DESC) AS WebSalesRank,
        RANK() OVER (ORDER BY COALESCE(TotalCatalogSales, 0) DESC) AS CatalogSalesRank,
        RANK() OVER (ORDER BY COALESCE(TotalStoreSales, 0) DESC) AS StoreSalesRank
    FROM 
        CustomerSales c
), HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        TotalSales
    FROM 
        SalesStats c
    WHERE 
        TotalSales >= (SELECT AVG(TotalSales) FROM SalesStats)
)
SELECT 
    c.c_customer_id,
    c.TotalWebSales,
    c.TotalCatalogSales,
    c.TotalStoreSales,
    CASE 
        WHEN c.TotalSales IS NULL THEN 'No Sales'
        WHEN c.TotalSales > 5000 THEN 'High Value'
        ELSE 'Regular'
    END AS CustomerType,
    ws.d_holiday AS IsHoliday
FROM 
    SalesStats c
LEFT JOIN 
    date_dim ws ON ws.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
WHERE 
    ws.d_holiday = 'Y' OR c.c_customer_id IN (SELECT c_customer_id FROM HighValueCustomers)
ORDER BY 
    TotalSales DESC
LIMIT 100;
