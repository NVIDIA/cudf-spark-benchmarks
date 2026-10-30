
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_paid) AS avg_sales,
        MAX(ss.ss_net_paid) AS max_sale,
        MIN(ss.ss_net_paid) AS min_sale
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_id AS customer_id,
        cs.total_sales,
        cs.total_transactions,
        cs.avg_sales,
        cs.max_sale,
        cs.min_sale,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs 
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.total_transactions,
    tc.avg_sales,
    tc.max_sale,
    tc.min_sale
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;
