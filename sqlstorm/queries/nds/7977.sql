
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_revenue,
        SUM(ss.ss_ext_tax) AS total_tax
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.total_revenue,
        cs.total_tax,
        DENSE_RANK() OVER (ORDER BY cs.total_revenue DESC) AS revenue_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id AS customer_id,
    tc.total_sales,
    tc.total_revenue,
    tc.total_tax
FROM 
    TopCustomers tc
WHERE 
    tc.revenue_rank <= 10
ORDER BY 
    tc.total_revenue DESC;
