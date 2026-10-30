
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.customer_name, 
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ss.ss_store_sk
)

SELECT 
    t.customer_name, 
    t.total_spent, 
    COALESCE(s.total_profit, 0) AS store_profit,
    s.sales_count
FROM 
    TopCustomers t
LEFT JOIN 
    StoreSalesSummary s ON s.ss_store_sk = (SELECT ss.s_store_sk FROM store ss WHERE ss.s_store_name LIKE '%Super%')
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_spent DESC;
