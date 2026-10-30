
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        cs.total_sales,
        cs.total_transactions,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
FilteredCustomers AS (
    SELECT 
        rc.first_name,
        rc.last_name,
        rc.total_sales,
        rc.total_transactions
    FROM 
        RankedCustomers rc
    WHERE 
        rc.sales_rank <= 10
)
SELECT 
    CONCAT(fc.first_name, ' ', fc.last_name) AS full_name,
    fc.total_sales,
    fc.total_transactions
FROM 
    FilteredCustomers fc
ORDER BY 
    fc.total_sales DESC;
