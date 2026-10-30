
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        SUM(ss.ss_ext_sales_price) AS TotalStoreSales,
        COUNT(ss.ss_ticket_number) AS TotalPurchases
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk
),
OnlineSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS TotalWebSales,
        COUNT(ws.ws_order_number) AS TotalWebOrders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY ws.ws_bill_customer_sk
),
AggregateSales AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.TotalStoreSales, 0) AS StoreSales,
        COALESCE(os.TotalWebSales, 0) AS WebSales,
        (COALESCE(cs.TotalStoreSales, 0) + COALESCE(os.TotalWebSales, 0)) AS TotalSales,
        CASE 
            WHEN COALESCE(cs.TotalStoreSales, 0) + COALESCE(os.TotalWebSales, 0) > 1000 THEN 'High Spender'
            ELSE 'Regular Spender'
        END AS SpendingCategory
    FROM CustomerSales cs
    FULL OUTER JOIN OnlineSales os ON cs.c_customer_sk = os.ws_bill_customer_sk
)
SELECT 
    a.c_customer_sk,
    a.StoreSales,
    a.WebSales,
    a.TotalSales,
    a.SpendingCategory,
    ROW_NUMBER() OVER (PARTITION BY a.SpendingCategory ORDER BY a.TotalSales DESC) AS SalesRank
FROM AggregateSales a
WHERE a.TotalSales > 0
ORDER BY a.SpendingCategory, SalesRank
LIMIT 100;

