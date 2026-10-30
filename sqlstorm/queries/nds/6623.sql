WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450421 AND 2450427  
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_web_sales,
        cs.total_orders
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450421 AND 2450427  
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_web_sales,
    hvc.total_orders,
    s.total_store_sales,
    s.total_transactions,
    (hvc.total_web_sales + COALESCE(s.total_store_sales, 0)) AS overall_sales
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    StoreSalesSummary s ON hvc.c_customer_sk = s.ss_store_sk 
ORDER BY 
    overall_sales DESC
LIMIT 10;