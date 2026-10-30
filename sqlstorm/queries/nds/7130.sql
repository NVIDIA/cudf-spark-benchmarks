
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.rank,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    d.d_year,
    EXTRACT(MONTH FROM d.d_date) AS sale_month,
    COUNT(ws.ws_order_number) AS total_orders
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    tc.rank <= 10 AND
    d.d_year = 2023
GROUP BY 
    tc.rank, tc.c_first_name, tc.c_last_name, tc.total_spent, tc.order_count, d.d_year, sale_month
ORDER BY 
    tc.rank;
