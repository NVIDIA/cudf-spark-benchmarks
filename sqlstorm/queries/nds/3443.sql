
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS TotalWebSales,
        SUM(cs.cs_ext_sales_price) AS TotalCatalogSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalWebOrders,
        COUNT(DISTINCT cs.cs_order_number) AS TotalCatalogOrders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.TotalWebSales,
        cs.TotalCatalogSales,
        cs.TotalWebOrders,
        cs.TotalCatalogOrders,
        RANK() OVER (ORDER BY cs.TotalWebSales DESC) AS WebSalesRank,
        RANK() OVER (ORDER BY cs.TotalCatalogSales DESC) AS CatalogSalesRank
    FROM 
        CustomerSales cs
    WHERE 
        (cs.TotalWebSales IS NOT NULL OR cs.TotalCatalogSales IS NOT NULL)
        AND (cs.TotalWebSales > 1000 OR cs.TotalCatalogSales > 1000)
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.TotalWebSales, 0) AS WebSalesTotal,
    COALESCE(tc.TotalCatalogSales, 0) AS CatalogSalesTotal,
    tc.TotalWebOrders,
    tc.TotalCatalogOrders,
    GREATEST(tc.TotalWebSales, tc.TotalCatalogSales) AS HighestSales,
    CASE 
        WHEN tc.WebSalesRank IS NOT NULL THEN 'Web'
        WHEN tc.CatalogSalesRank IS NOT NULL THEN 'Catalog'
        ELSE 'None'
    END AS PreferredChannel
FROM 
    TopCustomers tc
WHERE 
    tc.WebSalesRank <= 10 OR tc.CatalogSalesRank <= 10
ORDER BY 
    HighestSales DESC;
