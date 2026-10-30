
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Regular Customers'
    END AS customer_category,
    COALESCE(ca.ca_city, 'Unknown') AS address_city
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE 
    tc.rank IS NOT NULL
ORDER BY 
    tc.total_spent DESC
LIMIT 50;
