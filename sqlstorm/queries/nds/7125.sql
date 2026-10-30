
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_net_profit,
        cs.total_transactions,
        cs.avg_sales_price,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS customer_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_transactions > 5
)
SELECT 
    tc.c_customer_id AS customer_id,
    tc.total_net_profit,
    tc.total_transactions,
    tc.avg_sales_price
FROM 
    TopCustomers tc
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
