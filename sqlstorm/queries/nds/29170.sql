
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM 
        customer c 
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c_customer_id, 
        c_first_name, 
        c_last_name, 
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
    FROM 
        CustomerSales
)
SELECT 
    tc.c_customer_id, 
    tc.c_first_name, 
    tc.c_last_name,
    tc.total_sales,
    SUBSTRING(tc.c_last_name, POSITION(' ' IN (tc.c_last_name || ' ')) + 1, LENGTH(tc.c_last_name)) AS last_name_extension,
    CONCAT(tc.c_first_name, ' ', LEFT(tc.c_last_name, 1), '.') AS short_name
FROM 
    TopCustomers tc
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.total_sales DESC;
