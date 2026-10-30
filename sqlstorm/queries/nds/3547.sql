
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    (SELECT COUNT(*) 
     FROM store_sales ss
     WHERE ss.ss_customer_sk = tc.c_customer_sk) AS total_store_purchases,
    (SELECT COUNT(*) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS total_web_purchases,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers'
    END AS customer_segment
FROM 
    TopCustomers tc
WHERE 
    (SELECT COUNT(*)
     FROM web_sales ws
     WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) > 0
    OR
    (SELECT COUNT(*)
     FROM store_sales ss
     WHERE ss.ss_customer_sk = tc.c_customer_sk) > 0
ORDER BY 
    tc.total_sales DESC;
