
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS TotalWebSales,
        SUM(cs.cs_ext_sales_price) AS TotalCatalogSales,
        SUM(ss.ss_ext_sales_price) AS TotalStoreSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalWebOrders,
        COUNT(DISTINCT cs.cs_order_number) AS TotalCatalogOrders,
        COUNT(DISTINCT ss.ss_ticket_number) AS TotalStoreOrders
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
IncomeDemographics AS (
    SELECT 
        h.hd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount,
        AVG(h.hd_income_band_sk) AS AvgIncomeBand
    FROM 
        household_demographics AS h
    JOIN 
        customer AS c ON h.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        h.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.TotalWebSales, 0) + COALESCE(cs.TotalCatalogSales, 0) + COALESCE(cs.TotalStoreSales, 0) AS TotalSales,
        (cs.TotalWebOrders + cs.TotalCatalogOrders + cs.TotalStoreOrders) AS TotalOrders,
        ROW_NUMBER() OVER (ORDER BY COALESCE(cs.TotalWebSales, 0) DESC) AS SalesRank
    FROM 
        CustomerSales AS cs
)
SELECT 
    ss.c_customer_sk,
    ss.TotalSales,
    ss.TotalOrders,
    id.CustomerCount,
    id.AvgIncomeBand
FROM 
    SalesSummary AS ss
JOIN 
    IncomeDemographics AS id ON ss.c_customer_sk = id.hd_demo_sk
WHERE 
    ss.TotalSales > 0
ORDER BY 
    ss.TotalSales DESC, ss.TotalOrders DESC
LIMIT 100;
