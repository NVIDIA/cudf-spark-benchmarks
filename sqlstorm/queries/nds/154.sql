WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS rn
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
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
        cs.purchase_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rn = 1
),
RecentReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_refunds,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk >= (SELECT MAX(d.d_date_sk) 
                                    FROM date_dim d 
                                    WHERE d.d_date = cast('2002-10-01' as date) - INTERVAL '30 days')
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.purchase_count,
    COALESCE(rr.total_refunds, 0) AS total_refunds,
    COALESCE(rr.return_count, 0) AS return_count,
    CASE 
        WHEN rr.total_refunds IS NOT NULL THEN 
            (tc.total_spent - rr.total_refunds) 
        ELSE 
            tc.total_spent 
    END AS net_spent
FROM 
    TopCustomers tc
LEFT JOIN 
    RecentReturns rr ON tc.c_customer_sk = rr.wr_returning_customer_sk
ORDER BY 
    net_spent DESC
LIMIT 10;