
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rank <= 10
),
StoreSalesSummary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS full_name,
    tc.total_spent,
    ts.total_sales,
    ts.total_transactions,
    COALESCE(ts.total_sales - tc.total_spent, 0) AS sales_difference
FROM 
    TopCustomers tc
JOIN 
    StoreSalesSummary ts ON ts.total_sales = (
        SELECT 
            MAX(total_sales) 
        FROM 
            StoreSalesSummary
    )
ORDER BY 
    tc.total_spent DESC;
