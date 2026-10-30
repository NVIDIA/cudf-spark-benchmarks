
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_salutation, c.c_first_name, c.c_last_name
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.full_name,
        cs.total_spent,
        cs.total_transactions,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerSales cs
)
SELECT 
    rc.full_name,
    rc.total_spent,
    rc.total_transactions,
    CASE 
        WHEN rc.total_spent >= 1000 THEN 'Gold'
        WHEN rc.total_spent >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM 
    RankedCustomers rc
WHERE 
    rc.total_transactions > 5
ORDER BY 
    rc.total_spent DESC
LIMIT 10;
