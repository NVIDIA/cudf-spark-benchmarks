
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS TotalStoreSales,
        SUM(ws.ws_ext_sales_price) AS TotalWebSales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesComparison AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        TotalStoreSales,
        TotalWebSales,
        CASE 
            WHEN TotalStoreSales > TotalWebSales THEN 'Store Sales Dominant'
            WHEN TotalStoreSales < TotalWebSales THEN 'Web Sales Dominant'
            ELSE 'Equal Sales'
        END AS SalesType
    FROM 
        CustomerSales c
)
SELECT 
    sc.c_customer_sk,
    sc.c_first_name,
    sc.c_last_name,
    sc.TotalStoreSales,
    sc.TotalWebSales,
    sc.SalesType,
    COUNT(sr.sr_return_quantity) AS TotalStoreReturns,
    COUNT(wr.wr_return_quantity) AS TotalWebReturns
FROM 
    SalesComparison sc
LEFT JOIN 
    store_returns sr ON sc.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    web_returns wr ON sc.c_customer_sk = wr.wr_returning_customer_sk
GROUP BY 
    sc.c_customer_sk, sc.c_first_name, sc.c_last_name, 
    sc.TotalStoreSales, sc.TotalWebSales, sc.SalesType
ORDER BY 
    TotalStoreSales DESC, TotalWebSales DESC;
