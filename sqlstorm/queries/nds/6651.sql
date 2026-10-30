
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*, 
        COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0) AS total_sales
    FROM 
        CustomerSales c
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    CASE
        WHEN tc.total_sales = 0 THEN 'No Sales'
        WHEN tc.total_sales < 100 THEN 'Low Value Customer'
        WHEN tc.total_sales < 500 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_segment
FROM 
    TopCustomers tc
WHERE 
    tc.total_sales > 0
ORDER BY 
    total_sales DESC
LIMIT 10;
