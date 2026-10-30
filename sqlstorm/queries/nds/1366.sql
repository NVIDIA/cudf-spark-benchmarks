
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cp.total_spent
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_id = c.c_customer_id
    WHERE 
        cp.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchases)
),
LateReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS late_returns_count
    FROM 
        web_returns wr
    JOIN 
        customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE 
        wr.wr_returned_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        c.c_customer_id
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.total_spent,
    COALESCE(lr.late_returns_count, 0) AS late_returns_count,
    CASE 
        WHEN COALESCE(lr.late_returns_count, 0) > 5 THEN 'Frequent Returner'
        ELSE 'Normal Customer'
    END AS customer_type
FROM 
    HighSpenders hs
LEFT JOIN 
    LateReturns lr ON hs.c_customer_id = lr.c_customer_id
ORDER BY 
    hs.total_spent DESC;
