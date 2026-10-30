
WITH  TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_quantity) AS total_quantity
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_quantity DESC
    LIMIT 10
),
Returns AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_quantity) AS total_returned_quantity
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
)
SELECT 
    tc.c_customer_sk, 
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name, 
    COALESCE(r.total_returned_quantity, 0) AS total_returns,
    ROW_NUMBER() OVER (PARTITION BY tc.c_customer_sk ORDER BY tc.total_quantity DESC) AS rank,
    CASE 
        WHEN COALESCE(r.total_returned_quantity, 0) > 0 THEN 'Has Returns' 
        ELSE 'No Returns' 
    END AS return_status
FROM TopCustomers tc
LEFT JOIN Returns r ON tc.c_customer_sk = r.cr_returning_customer_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_customer_sk = tc.c_customer_sk
    AND ss.ss_net_paid < (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2)
)
ORDER BY total_returns DESC, total_quantity DESC;
