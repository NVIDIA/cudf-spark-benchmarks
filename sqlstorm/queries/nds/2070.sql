
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year > 1970
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_paid,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_net_paid DESC) AS rank
    FROM CustomerSales cs
    WHERE cs.total_net_paid > (
        SELECT AVG(total_net_paid) FROM CustomerSales
    )
),
StoreReturnsDetails AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_net_paid,
    hvc.order_count,
    COALESCE(srd.total_returns, 0) AS total_returns,
    COALESCE(srd.return_count, 0) AS return_count,
    CASE 
        WHEN hvc.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM HighValueCustomers hvc
LEFT JOIN StoreReturnsDetails srd ON hvc.c_customer_sk = srd.sr_customer_sk
WHERE hvc.rank <= 10
ORDER BY hvc.total_net_paid DESC;
