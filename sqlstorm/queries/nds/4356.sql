
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
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
StoreSalesCTE AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    hvc.total_web_sales,
    (hvc.total_web_sales + COALESCE(ss.total_store_sales, 0)) AS combined_sales
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    StoreSalesCTE ss ON hvc.c_customer_sk = ss.ss_customer_sk
ORDER BY 
    combined_sales DESC
LIMIT 10;
