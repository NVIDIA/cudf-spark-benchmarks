
WITH CustomerPayments AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_paid,
        COUNT(DISTINCT ws.ws_order_number) + COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cp.c_customer_sk, 
        cp.c_first_name, 
        cp.c_last_name,
        cp.total_paid,
        DENSE_RANK() OVER (ORDER BY cp.total_paid DESC) AS rnk
    FROM 
        CustomerPayments cp
    WHERE 
        cp.total_paid > (SELECT AVG(total_paid) FROM CustomerPayments)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    CASE 
        WHEN hvc.rnk <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    (SELECT COUNT(*) FROM store_returns sr 
     WHERE sr.sr_customer_sk = hvc.c_customer_sk AND sr.sr_return_quantity > 0
    ) AS return_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM store_returns sr 
              WHERE sr.sr_customer_sk = hvc.c_customer_sk AND sr.sr_return_quantity > 0) > 5 
        THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS return_behavior
FROM 
    HighValueCustomers hvc
    LEFT JOIN customer_address ca ON hvc.c_customer_sk = ca.ca_address_sk
    JOIN customer c ON hvc.c_customer_sk = c.c_customer_sk
ORDER BY 
    hvc.total_paid DESC, 
    hvc.c_customer_sk
LIMIT 20;
