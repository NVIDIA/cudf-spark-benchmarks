
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS TotalWebSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalWebOrders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid_inc_tax) AS TotalStoreSales,
        COUNT(DISTINCT ss.ss_ticket_number) AS TotalStoreOrders
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
AggregatedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name, 
        cs.c_last_name,
        COALESCE(cs.TotalWebSales, 0) AS TotalWebSales,
        COALESCE(ss.TotalStoreSales, 0) AS TotalStoreSales,
        COALESCE(cs.TotalWebOrders, 0) AS TotalWebOrders,
        COALESCE(ss.TotalStoreOrders, 0) AS TotalStoreOrders
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
)
SELECT 
    a.c_first_name,
    a.c_last_name,
    a.TotalWebSales,
    a.TotalStoreSales,
    a.TotalWebOrders,
    a.TotalStoreOrders,
    (a.TotalWebSales + a.TotalStoreSales) AS TotalSales,
    CASE 
        WHEN (a.TotalWebSales + a.TotalStoreSales) = 0 THEN 'No Sales' 
        ELSE 'Has Sales' 
    END AS Sales_Status
FROM 
    AggregatedSales a
WHERE 
    (a.TotalWebSales > 1000 OR a.TotalStoreSales > 1000)
ORDER BY 
    TotalSales DESC
LIMIT 10;
