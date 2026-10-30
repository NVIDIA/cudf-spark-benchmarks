WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    tc.total_orders,
    tc.total_spent
FROM 
    TopCustomers tc
JOIN 
    customer cu ON tc.c_customer_sk = cu.c_customer_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;