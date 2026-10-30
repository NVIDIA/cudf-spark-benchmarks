
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.rn = 1 AND cs.total_spent IS NOT NULL
),
MonthlySales AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_net_paid) AS monthly_total
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    COALESCE(ms.monthly_total, 0) AS monthly_total,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = tc.c_customer_sk) AS store_order_count
FROM 
    TopCustomers tc
LEFT JOIN 
    MonthlySales ms ON ms.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') AND ms.d_month_seq = EXTRACT(MONTH FROM DATE '2002-10-01')
WHERE 
    tc.total_spent > (SELECT AVG(total_spent) FROM TopCustomers) 
ORDER BY 
    tc.total_spent DESC
LIMIT 10;
