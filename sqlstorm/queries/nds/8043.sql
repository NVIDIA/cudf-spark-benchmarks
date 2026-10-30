
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS TotalWebSales,
        COUNT(ws.ws_order_number) AS TotalOrders,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
SalesAnalytics AS (
    SELECT 
        TotalWebSales,
        TotalOrders,
        cd_gender,
        cd_marital_status,
        SUM(CASE WHEN TotalWebSales > 1000 THEN 1 ELSE 0 END) AS HighValueCustomers,
        AVG(TotalOrders) AS AvgOrders
    FROM 
        CustomerSales
    GROUP BY 
        TotalWebSales, TotalOrders, cd_gender, cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(*) AS CustomerCount,
    SUM(TotalWebSales) AS TotalWebSales,
    AVG(AvgOrders) AS AvgOrders,
    MAX(TotalWebSales) AS MaxSale,
    MIN(TotalWebSales) AS MinSale,
    SUM(HighValueCustomers) AS TotalHighValueCustomers
FROM 
    SalesAnalytics
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    TotalWebSales DESC;
