
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
),
FrequentReturners AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    hvc.total_orders,
    hvc.total_spent,
    fr.return_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    FrequentReturners fr ON hvc.c_customer_sk = fr.sr_customer_sk
JOIN 
    customer c ON hvc.c_customer_sk = c.c_customer_sk
ORDER BY 
    hvc.total_spent DESC, fr.return_count DESC
LIMIT 10;
